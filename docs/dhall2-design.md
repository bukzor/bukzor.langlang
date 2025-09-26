# Dhall2: Recursion with Termination Guarantees

## The Core Insight

Dhall2 extends Dhall with general recursion while preserving strong normalization by encoding recursive functions in System F-omega. If a function can be encoded in F-omega, it's guaranteed to terminate.

## What Dhall Currently Can't Do

```dhall
-- ❌ Current Dhall: No general recursion
let factorial = λ(n : Natural) →
  if n == 0 then 1 else n * factorial (n - 1)
  -- Error: variable 'factorial' not in scope

-- ❌ Current Dhall: No loops with unknown bounds
let replicate = λ(n : Natural) → λ(x : Text) →
  List/build Text (λ(list : Type) → λ(cons : Text → list → list) → λ(nil : list) →
    -- Complex Church encoding required
  )

-- ❌ Current Dhall: No recursive data processing
let processTree = λ(tree : Tree) →
  case tree of
    Leaf x → x
    Branch left right → merge (processTree left) (processTree right)
    -- Error: recursive call not allowed
```

## Dhall2 Syntax Extensions

### 1. Recursive Functions with Termination Annotations

```dhall
-- ✅ Dhall2: Recursive functions with termination proofs
let factorial : Natural → Natural = fix (λ(f : Natural → Natural) →
  λ(n : Natural) →
    if n == 0
    then 1
    else n * f (n - 1))
  terminating_by structural_recursion(n)

-- ✅ Dhall2: List processing with bounded recursion
let replicate : Natural → Text → List Text =
  fix (λ(f : Natural → Text → List Text) →
    λ(n : Natural) → λ(x : Text) →
      if n == 0
      then ([] : List Text)
      else [x] # f (n - 1) x)
  terminating_by bounded_recursion(n)

-- ✅ Dhall2: Tree processing with structural recursion
let treeSum : Tree Natural → Natural =
  fix (λ(f : Tree Natural → Natural) →
    λ(tree : Tree Natural) →
      case tree of
        Leaf x → x
        Branch left right → f left + f right)
  terminating_by structural_recursion(tree)
```

### 2. Termination Annotations

```dhall
-- Structural recursion (most common)
terminating_by structural_recursion(parameter)

-- Bounded recursion (known upper bound)
terminating_by bounded_recursion(fuel)

-- Well-founded recursion (custom ordering)
terminating_by well_founded_recursion(measure)

-- Lexicographic ordering (multiple parameters)
terminating_by lexicographic_recursion(param1, param2)
```

### 3. Sized Types (Advanced)

```dhall
-- Size-indexed types for compile-time termination checking
let List/length : ∀(n : Size) → ∀(a : Type) → List[n] a → Natural[n]

let factorial : ∀(n : Natural) → Natural[factorial_size(n)] =
  λ(n : Natural) →
    if n == 0
    then 1
    else n * factorial (n - 1)
    -- Type checker verifies: factorial_size(n-1) < factorial_size(n)
```

## F-omega Encoding Strategy

### 1. Simple Recursion → Church Encoding

```dhall
-- Dhall2 source
let factorial = fix (λ(f : Natural → Natural) →
  λ(n : Natural) → if n == 0 then 1 else n * f (n - 1))

-- F-omega encoding
ΛSize. λ(n : Natural[Size]).
  (Natural[Size] → Natural[Size]) → Natural[Size] → Natural[Size]
  (λ(f : Natural[Size] → Natural[Size]) →
    λ(m : Natural[Size]) →
      if (isZero m)
      then (succ zero)
      else (mult m (f (pred m))))
  -- The size parameter ensures termination
```

### 2. Bounded Recursion → Resource Monad

```dhall
-- Dhall2 source
let bounded_loop = λ(n : Natural) →
  fix (λ(f : Natural → List Natural) →
    λ(i : Natural) →
      if i >= n then [] else [i] # f (i + 1))
  terminating_by bounded_recursion(n)

-- F-omega encoding
λ(fuel : Natural).
  Resource fuel (List Natural)
  -- Resource monad tracks remaining "fuel"
  -- Type system ensures fuel decreases
```

### 3. Structural Recursion → Inductive Types

```dhall
-- Dhall2 source
let treeSize = fix (λ(f : Tree → Natural) →
  λ(tree : Tree) →
    case tree of
      Leaf → 1
      Branch left right → 1 + f left + f right)

-- F-omega encoding
λ(tree : μTree. Unit + Tree × Tree).
  Tree_fold Natural tree (λ_ → 1) (λleft_size → λright_size → 1 + left_size + right_size)
  -- μ-types ensure structural decreasing
```

## Implementation Strategy

### 1. Parsing Extensions

Extend Dhall parser to recognize:
- `fix` keyword for recursive definitions
- `terminating_by` annotations
- Termination strategy specifications

### 2. Termination Analysis

Before F-omega encoding, verify:
```rust
// Termination checker
fn check_termination(expr: &RecursiveExpr) -> Result<TerminationProof, TerminationError> {
    match expr.strategy {
        StructuralRecursion(param) => check_structural_decrease(expr, param),
        BoundedRecursion(bound) => check_bounded_decrease(expr, bound),
        WellFoundedRecursion(measure) => check_well_founded(expr, measure),
    }
}
```

### 3. F-omega Encoding

```rust
// Encoder: Dhall2 → F-omega
fn encode_recursive_function(
    func: &RecursiveFunction,
    proof: TerminationProof
) -> FomegaTerm {
    match proof {
        Structural => encode_as_fold(func),
        Bounded => encode_as_resource_monad(func),
        WellFounded => encode_as_church_numeral(func),
    }
}
```

### 4. Evaluation

The F-omega self-interpreter evaluates the encoded term:
```rust
fn evaluate_fomega(term: FomegaTerm) -> Value {
    // Strong normalization guaranteed by F-omega
    // All recursive functions are guaranteed to terminate
    self_interpret_fomega(term)
}
```

## Example: Kubernetes Manifest Generation

This is what Dhall2 enables that current Dhall cannot:

```dhall
-- Generate N replicas (impossible in current Dhall)
let generateReplicas : Natural → Text → List Deployment =
  fix (λ(f : Natural → Text → List Deployment) →
    λ(count : Natural) → λ(name : Text) →
      if count == 0
      then ([] : List Deployment)
      else [makeDeployment "${name}-${Natural/show count}"] # f (count - 1) name)
  terminating_by bounded_recursion(count)

-- Process nested configuration recursively
let processConfig : Config → Config =
  fix (λ(f : Config → Config) →
    λ(config : Config) →
      config // {
        databases = List/map Database Database (λ(db : Database) →
          db // { replicas = List/map Replica Replica f db.replicas }
        ) config.databases
      })
  terminating_by structural_recursion(config)

-- Template expansion with guaranteed termination
let expandTemplate : Template → Variables → Text =
  fix (λ(f : Template → Variables → Text) →
    λ(template : Template) → λ(vars : Variables) →
      case template of
        Literal text → text
        Variable name →
          Optional/fold Text (Map/lookup name vars) Text (λ(x : Text) → x) ""
        Concat templates →
          List/fold Template templates Text (λ(t : Template) → λ(acc : Text) →
            acc ++ f t vars) ""
      )
  terminating_by structural_recursion(template)
```

## The Termination Guarantee

**Key insight**: If Dhall2 code can be encoded in System F-omega, it's guaranteed to terminate because:

1. **System F-omega is strongly normalizing** (proven)
2. **The encoding preserves semantics** (by construction)
3. **Type checking the encoding proves termination** (automatically)

Users write recursive Dhall2 code, but get mathematical guarantees that it will always halt.

## Migration Path

```dhall
-- Phase 1: Existing Dhall (no changes)
let simple = λ(x : Natural) → x + 1

-- Phase 2: Add terminating recursion
let factorial = fix (λ(f : Natural → Natural) →
  λ(n : Natural) → if n == 0 then 1 else n * f (n - 1))
  terminating_by structural_recursion(n)

-- Phase 3: Advanced features (sized types, etc.)
let advanced = ... -- Future work
```

## Research Questions

1. **What's the largest class of recursive functions encodable in F-omega?**
2. **Can we infer termination annotations automatically?**
3. **How do we handle mutually recursive functions?**
4. **What's the performance overhead of the encoding?**

The hypothesis: The subset that's encodable in F-omega is exactly the subset that's useful for configuration generation.