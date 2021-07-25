# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Ngon(p1, p2, ..., pN)

A N-gon is a polygon with `N` vertices `p1`, `p2`, ..., `pN`
oriented counter-clockwise (CCW). In this case the number of
vertices is fixed and known at compile time. Examples of N-gon
are `Triangle` (N=3), `Quadrangle` (N=4), `Pentagon` (N=5), etc.

### Notes

- Although the number of vertices `N` is known at compile time,
  we use abstract vectors to store the list of vertices. This
  design allows constructing N-gon from views of global vectors
  without expensive memory allocations.

- Type aliases are `Triangle`, `Quadrangle`, `Pentagon`, `Hexagon`,
  `Heptagon`, `Octagon`, `Nonagon`, `Decagon`.
"""
struct Ngon{N,Dim,T,V<:AbstractVector{Point{Dim,T}}} <: Polygon{Dim,T}
  vertices::V
end

Ngon{N}(vertices::AbstractVector{Point{Dim,T}}) where {N,Dim,T} =
  Ngon{N,Dim,T,typeof(vertices)}(vertices)

Ngon(vertices::AbstractVector{Point{Dim,T}}) where {Dim,T} =
  Ngon{length(vertices)}(vertices)

# type aliases for convenience
const Triangle   = Ngon{3}
const Quadrangle = Ngon{4}
const Pentagon   = Ngon{5}
const Hexagon    = Ngon{6}
const Heptagon   = Ngon{7}
const Octagon    = Ngon{8}
const Nonagon    = Ngon{9}
const Decagon    = Ngon{10}

issimple(::Type{<:Ngon}) = true

nvertices(::Type{<:Ngon{N}}) where {N} = N
nvertices(ngon::Ngon) = nvertices(typeof(ngon))

# measure of N-gon embedded in 2D
function signarea(ngon::Ngon{N,2}) where {N}
  v = ngon.vertices
  sum(i -> signarea(v[1], v[i], v[i+1]), 2:N-1)
end
measure(ngon::Ngon{N,2}) where {N} = abs(signarea(ngon))

function edges(c::Triangle)
  all_edges = ((c.vertices[1],c.vertices[2]), (c.vertices[2],c.vertices[3]),
  (c.vertices[3],c.vertices[1]))
  (Segment([all_edges[i]...]) for i in 1:3)
end
function edges(c::Quadrangle)
  all_edges = ((c.vertices[1],c.vertices[2]), (c.vertices[2],c.vertices[3]),
  (c.vertices[3],c.vertices[4]), (c.vertices[4],c.vertices[1]))
  (Segment([all_edges[i]...]) for i in 1:4)
end

# measure of N-gon embedded in higher dimension
function measure(ngon::Ngon{N}) where {N}
  areaₜ(A, B, C) = norm((B - A) × (C - A)) / 2
  v = ngon.vertices
  sum(i -> areaₜ(v[1], v[i], v[i+1]), 2:N-1)
end

hasholes(::Ngon) = false

chains(ngon::Ngon{N}) where {N} = [Chain(ngon.vertices[[1:N; 1]])]

Base.unique!(ngon::Ngon) = ngon

function Base.in(p::Point{2,T}, t::Triangle{2,T}) where {T}
  # given coordinates
  a, b, c = t.vertices
  x₁, y₁ = coordinates(a)
  x₂, y₂ = coordinates(b)
  x₃, y₃ = coordinates(c)
  x , y  = coordinates(p)

  # barycentric coordinates
  λ₁ = ((y₂ - y₃)*(x  - x₃) + (x₃ - x₂)*(y  - y₃)) /
       ((y₂ - y₃)*(x₁ - x₃) + (x₃ - x₂)*(y₁ - y₃))
  λ₂ = ((y₃ - y₁)*(x  - x₃) + (x₁ - x₃)*(y  - y₃)) /
       ((y₂ - y₃)*(x₁ - x₃) + (x₃ - x₂)*(y₁ - y₃))
  λ₃ = one(T) - λ₁ - λ₂

  # barycentric check
  zero(T) ≤ λ₁ ≤ one(T) &&
  zero(T) ≤ λ₂ ≤ one(T) &&
  zero(T) ≤ λ₃ ≤ one(T)
end

function Base.in(p::Point{Dim,T}, ngon::Ngon{N,Dim,T}) where {N,Dim,T}
  # decompose n-gons into triangles by
  # fan triangulation (assumes convexity)
  # https://en.wikipedia.org/wiki/Fan_triangulation
  v = ngon.vertices
  Δ(i) = Triangle(view(v, [1,i,i+1]))
  any(i -> p ∈ Δ(i), 2:N-1)
end

# triangles are special
issimplex(::Type{<:Triangle}) = true
isconvex(::Type{<:Triangle}) = true
