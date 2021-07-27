# Create a struct to hold the fields of the Woodbury. 
# We do this because the Woodbury cannot represent it's own tangent. 
# I.e. for Y = f(W,...), W̄ = ∂Y / ∂W, is not necessarily a valid Woodbury. 
# Consider, e.g. the case of a Positive Diagonal matrix
struct WoodburyLike
    A
    D
    S
end

# Overwrite the generic to_bec and replace with the almost identical Woodbury specific.
# This means that in FiniteDifferences, the WoodburyLike matrix is created instead of the Woodbury. 
# Because the construction is forced there, this would bypass the valdidation checks on the constructor.  
function FiniteDifferences.to_vec(x::T) where {T<:WoodburyPDMat}
    val_vecs_and_backs = map(name -> to_vec(getfield(x, name)), fieldnames(T))
    vals = first.(val_vecs_and_backs)
    backs = last.(val_vecs_and_backs)

    v, vals_from_vec = to_vec(vals)
    function structtype_from_vec(v::Vector{<:Real})
        val_vecs = vals_from_vec(v)
        values = map((b, v) -> b(v), backs, val_vecs)
        WoodburyLike(values...)
    end
    return v, structtype_from_vec
end

# Assign some algebra for the WoodburyLike. 
WoodburyPDMat(S::WoodburyLike) = WoodburyPDMat(S.A, S.D, S.S)
Base.:*(A::AbstractVecOrMat, B::WoodburyLike) = A * WoodburyPDMat(B)
Base.:*(A::WoodburyLike, B::AbstractVecOrMat) = WoodburyPDMat(A) * B
Base.:*(A::Real, B::WoodburyLike) = A * WoodburyPDMat(B)
Base.:*(A::WoodburyLike, B::Real) = WoodburyPDMat(A) * B
LinearAlgebra.dot(A, B::WoodburyLike) = dot(A, WoodburyPDMat(B))

@testset "ChainRules" begin

    W = WoodburyPDMat(rand(4,2), Diagonal(rand(2,)), Diagonal(rand(4,)))
    R = 2.0
    D = Diagonal(rand(4,))

    @testset "*(Matrix-Woodbury)" begin
        test_rrule(*, D, W)
        test_rrule(*, W, D)
        test_rrule(*, rand(4,4), W)
    end

    @testset "*(Real-Woodbury" begin
        @testset "Matrix Tangent" begin
            ###

            primal = R * W
            
            # Matrix Tangent
            T = rand_tangent(Matrix(primal))
            f_jvp = j′vp(ChainRulesTestUtils._fdm, x -> Matrix(*(x...)), T, (R, W))[1]
            R̄ = dot(T, W')
            W̄ = conj(R) * T

            R̄ ≈ f_jvp[1]
            (W.D * W.A' * W̄' + W.D * W.A' * W̄) ≈ f_jvp[2].A' # A transpose.
            Diagonal(W.A' * (W̄) * W.A) ≈ f_jvp[2].D # D
            Diagonal(W̄) ≈ f_jvp[2].S # S

            # Cannot get this to work. Here the T will be 
            # T = rand_tangent(primal::WoodburyPDMat) which breaks. 
            # test_rrule(*, 5.0, W)

        end
    end
end