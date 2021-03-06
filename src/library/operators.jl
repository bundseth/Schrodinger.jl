"""
    qzero(N, dims=(N,))

Generate a zero operator for a Hilbert space of size `N`. It is possible to specify the subspace dimensions with the `dims` argument. Returns a sparse matrix.

# Example
```jldoctest
julia> qzero(4,(2,2))
4×4 Schrodinger.Operator{SparseMatrixCSC{Float64,Int64},2} with space dimensions 2⊗2:
 0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0
```
"""
function qzero(N::Integer, dims::SDims=(N,))
    rowval = Vector{Int}(0)
    colptr = ones(Int,N+1)
    nzval  = Vector{Float64}(0)
    return Operator(SparseMatrixCSC(N,N,colptr,rowval,nzval),dims,true)
end


"""
    qeye(N, dims=(N,))

Generate an identity operator for a Hilbert space of size `N`. It is possible to specify the subspace dimensions with the `dims` argument. Returns a sparse matrix.

# Example
```jldoctest
julia> qeye(4,(2,2))
4×4 Schrodinger.Operator{SparseMatrixCSC{Float64,Int64},2} with space dimensions 2⊗2:
 1.0  0.0  0.0  0.0
 0.0  1.0  0.0  0.0
 0.0  0.0  1.0  0.0
 0.0  0.0  0.0  1.0
```
"""
function qeye(N::Integer, dims::SDims=(N,))
    rowval = collect(1:N)
    colptr = Vector{Int}(N+1); colptr[1:N] = rowval; colptr[end] = N+1
    nzval  = ones(N)
    return Operator(SparseMatrixCSC(N,N,colptr,rowval,nzval),dims,true)
end

"""
    destroy(N)

Generate a quantum harmonic oscillator lowering (annihilation) operator \$\\hat{a}\$ in a truncated Hilbert space of size `N`. Returns a sparse matrix.

# Example
```jldoctest
julia> destroy(4)
4×4 Schrodinger.Operator{SparseMatrixCSC{Float64,Int64},1} with space dimensions 4:
 0.0  1.0  0.0      0.0
 0.0  0.0  1.41421  0.0
 0.0  0.0  0.0      1.73205
 0.0  0.0  0.0      0.0
```
"""
function destroy(N::Integer)
    rowval = collect(1:N-1)
    colptr = Vector{Int}(N+1); colptr[1] = 1; colptr[2:end] = 1:N
    nzval  = [sqrt(i) for i in 1:N-1]
    return Operator(SparseMatrixCSC(N,N,colptr,rowval,nzval),(N,),false)
end

"""
    create(N)

Generate a quantum harmonic oscillator raising (creation) operator \$\\hat{a}^†\$ in a truncated Hilbert space of size `N`. Returns a sparse matrix.

# Example
```jldoctest
julia> create(4)
4×4 Schrodinger.Operator{SparseMatrixCSC{Float64,Int64},1} with space dimensions 4:
 0.0  0.0      0.0      0.0
 1.0  0.0      0.0      0.0
 0.0  1.41421  0.0      0.0
 0.0  0.0      1.73205  0.0
```
"""
function create(N::Integer)
    rowval = collect(2:N)
    colptr = Vector{Int}(N+1); colptr[1:N] = 1:N; colptr[end] = N
    nzval  = [sqrt(i) for i in 1:N-1]
    return Operator(SparseMatrixCSC(N,N,colptr,rowval,nzval),(N,),false)
end

"""
    numberop(N)

Generate a number operator \$\\hat{n}\$ in a Hilbert space of size `N`. Returns a sparse matrix.

# Example
```jldoctest
julia> numberop(4)
4×4 Schrodinger.Operator{SparseMatrixCSC{Float64,Int64},1} with space dimensions 4:
 0.0  0.0  0.0  0.0
 0.0  1.0  0.0  0.0
 0.0  0.0  2.0  0.0
 0.0  0.0  0.0  3.0
```
"""
function numberop(N::Integer)
    # "nzval" includes a structural 0 for the [1,1] entry
    rowval = collect(1:N)
    colptr = Vector{Int}(N+1); colptr[1:N] = rowval; colptr[end] = N+1
    nzval  = [float(n) for n = 0:N-1]
    return Operator(SparseMatrixCSC(N,N,colptr,rowval,nzval),(N,),true)
end

"""
    displacementop(N, α)

Generate a quantum harmonic oscillator displacement operator \$\\hat{D}(α)\$ in a truncated Hilbert space of size `N`. Returns a dense matrix.

```math
\\hat{D}(α) = \\exp\\left(α\\hat{a}^† - α^*\\hat{a}\\right)
```

# Example
```jldoctest
julia> displacementop(3,0.5im)
3×3 Schrodinger.Operator{Array{Complex{Float64},2},1} with space dimensions 3:
   0.88262+0.0im            0.0+0.439802im  -0.166001+0.0im
       0.0+0.439802im  0.647859+0.0im             0.0+0.621974im
 -0.166001+0.0im            0.0+0.621974im    0.76524+0.0im
```
"""
function displacementop(N::Integer, α::Number)
    a = full(destroy(N))
    return Operator(expm(α.*a' .- α'.*a),(N,),false)
end

"""
    squeezeop(N, z)

Generate a quantum harmonic oscillator squeeze operator \$\\hat{S}(z)\$ in a truncated Hilbert space of size `N`. Returns a dense matrix.

```math
\\hat{S}(z) = \\exp\\left(\\frac{1}{2}\\left(z^*\\hat{a}^2 - z\\hat{a}^{†2}\\right)\\right)
```

# Example
```jldoctest
julia> squeezeop(3,0.5im)
3×3 Schrodinger.Operator{Array{Complex{Float64},2},1} with space dimensions 3:
 0.938148+0.0im       0.0+0.0im       0.0-0.346234im
      0.0+0.0im       1.0+0.0im       0.0+0.0im
      0.0-0.346234im  0.0+0.0im  0.938148+0.0im
```
"""
function squeezeop(N::Integer, z::Number)
    a = full(destroy(N))
    return Operator(expm(0.5.*(z'.*a^2 .- z.*a'^2)),(N,),false)
end

"""
    projectorop(N,S)

Generate a projector on the subspaces defined by an integer or a vector/range of integers `S`:

```math
P = \\sum_{i∈S} |i⟩⟨i|.
```

# Example
```jldoctest
julia> projectorop(5,[1,3])
5×5 Schrodinger.Operator{SparseMatrixCSC{Float64,Int64},1} with space dimensions 5:
 0.0  0.0  0.0  0.0  0.0
 0.0  1.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  1.0  0.0
 0.0  0.0  0.0  0.0  0.0
```
"""
function projectorop{T<:Integer}(N::Integer,S::AbstractVector{T})
    maximum(S)<N || throw(ArgumentError("a $N-d space cannot be projected on level $(maximum(S))"))
    I = S.+1
    V = ones(length(S))
    return Operator(sparse(I,I,V,N,N),(N,),true)
end
projectorop(N::Integer,S::Integer) = projectorop(N,S:S)

"""
    sylvesterop(N,k,l)

Generate the \$(i,j)^{\textrm{th}}\$ Sylvester generalized Pauli matrix in N-d.
https://en.wikipedia.org/wiki/Generalizations_of_Pauli_matrices
"""
function sylvesterop(N::Integer,k::Integer,l::Integer)
    ωˡ = Complex(cospi(2l/N),sinpi(2l/N))
    rowval = mod1.(collect(1:N).+k,N)
    colptr = Vector{Int}(N+1); colptr[1:N] = 1:N; colptr[end] = N+1
    nzval  = [ωˡ^m for m in 0:N-1]
    return Operator(SparseMatrixCSC(N,N,colptr,rowval,nzval),(N,),false)
end

function Sigma1(N)
    rowval = circshift(collect(1:N),-1)
    colptr = Vector{Int}(N+1); colptr[1:N] = 1:N; colptr[end] = N+1
    nzval  = ones(N)
    return Operator(SparseMatrixCSC(N,N,colptr,rowval,nzval),(N,),false)
end

function Sigma3(N)
    ω = Complex(cospi(2/N),sinpi(2/N))
    rowval = collect(1:N)
    colptr = Vector{Int}(N+1); colptr[1:N] = 1:N; colptr[end] = N+1
    nzval  = [ω^m for m=0:N-1]
    return Operator(SparseMatrixCSC(N,N,colptr,rowval,nzval),(N,),false)
end
