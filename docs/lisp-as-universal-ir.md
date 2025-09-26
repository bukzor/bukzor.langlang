# Lisp as Universal Intermediate Representation

## The Core Insight

Any configuration language's CST/AST can be represented as s-expressions (Lisp). This means we can "de-sugar" all config languages to the same core representation.

## All Config Languages Compile To This

```lisp
;; Every config language fundamentally does:
(let ((config
  (merge                                    ; Composition
    (validate                               ; Constraint checking
      (transform                            ; Computation
        (import "base.config")              ; Modularity
        (lambda (x) ...)                    ; Functions
        (if condition then-val else-val)   ; Conditionals
        (map/filter/reduce ...))            ; List operations
      (schema ...))                         ; Type/constraint definition
    (override ...))))                      ; Configuration overlay
  (serialize config 'json))                ; Output generation
```

## The Minimal Core

Every configuration language needs exactly these primitives:

```lisp
;; 1. Data literals
(dict "key" value ...)
(list item1 item2 ...)
(string "text")
(number 42)
(bool true)

;; 2. Abstraction
(lambda (x) body)
(let ((x value)) body)

;; 3. Computation
(if test then else)
(merge dict1 dict2)

;; 4. Validation
(assert predicate value error-msg)

;; 5. Import/modularity
(import module-spec)
```

## Proof By Example

### Dhall
```dhall
let x = 5 in x + 1
```
Becomes:
```lisp
(let ((x 5)) (+ x 1))
```

### Jsonnet
```jsonnet
local x = 5;
{result: x + 1}
```
Becomes:
```lisp
(let ((x 5))
  (dict "result" (+ x 1)))
```

### Python Config
```python
x = 5
config = {"result": x + 1}
```
Becomes:
```lisp
(let ((x 5))
  (let ((config (dict "result" (+ x 1))))
    config))
```

### KCL
```kcl
schema Config:
    x: int = 5
    result = x + 1
```
Becomes:
```lisp
(define-schema Config
  (let ((x (typed 'int 5)))
    (dict "result" (+ x 1))))
```

## The Unification

Once everything is s-expressions, the differences are just:

1. **When validation happens**: `(validate-at 'compile ...)` vs `(validate-at 'runtime ...)`
2. **What computation is allowed**: `(ensure-terminating ...)` vs `(allow-recursion ...)`
3. **How effects are handled**: `(pure ...)` vs `(with-effects ...)`

## Why This Matters

- **One parser to rule them all**: Parse any syntax to s-expressions
- **One evaluator**: Interpret the s-expressions with pluggable strategies
- **One type system**: Apply type checking to the uniform representation
- **One optimizer**: Common optimizations work on all languages
- **One compiler**: Target WASM/native code from single IR

The surface syntax is just sugar. The core is always the same Lisp.