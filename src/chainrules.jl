@non_differentiable validate_woodbury_arguments(A, D, S)

function ChainRulesCore.rrule(
    ::typeof(*), A::Real, B::WoodburyPDMat{T, TA, TD, TS}
) where {T, TA, TD, TS}
    project_A = ProjectTo(A)
    project_B = ProjectTo(B)

    function times_pullback(ȳ::AbstractMatrix)
        Ȳ = unthunk(ȳ)
        Ā = dot(Ȳ, B)
        B̄ = A' * Ȳ
        return (
           NoTangent(),
           @thunk(project_A(Ā')),
           @thunk(project_B(B̄)),
        )
    end

    function times_pullback(ȳ::Tangent{<:WoodburyPDMat})
        Ȳ = unthunk(ȳ)
        Ā = dot(Ȳ.A * Ȳ.D * Ȳ.A' + Ȳ.S, B)
        B̄ = Ȳ.A * (A' * Ȳ.D) * Ȳ.A' + A' * Ȳ.S
        return (
           NoTangent(),
           @thunk(project_A(Ā')),
           @thunk(project_B(B̄)),
        )
    end
    return A * B, times_pullback
end

function ChainRulesCore.ProjectTo(W::WoodburyPDMat)
    function dW(W̄)
        Ā(W̄) = ProjectTo(W.A)(collect((W.D * W.A' * W̄' + W.D * W.A' * W̄)'))
        D̄(W̄) = ProjectTo(W.D)(W.A' * (W̄) * W.A)
        S̄(W̄) = ProjectTo(W.S)(W̄)
        return Tangent{typeof(W)}(; A = Ā(W̄), D = D̄(W̄), S = S̄(W̄))
    end
    return dW
end




