# Commonalities Analysis: Configuration Languages

## The Common Denominator System

After analyzing Dhall, KCL, Nickel, Pkl, Ytt, Jsonnet, and CUE, clear patterns emerge:

### Universal Components

1. **JSON as Base Data Model**
   - All produce JSON-compatible output
   - All extend JSON with computation
   - All preserve JSON's fundamental types

2. **Functional Core**
   - Functions (first-class or limited)
   - Immutability (default or enforced)
   - Expression-based (everything returns a value)

3. **Module System**
   - Import mechanisms (file/URL/package)
   - Namespace management
   - Export control

4. **Validation Layer**
   - Types (static/dynamic/gradual)
   - Schemas (structural/nominal)
   - Constraints (inline/separate)

5. **Purity Guarantees**
   - 70-95% pure across all languages
   - Deterministic evaluation
   - Controlled or no side effects

## Dimensional Analysis

### Safety Dimension
```
           Static ←─────────────→ Dynamic
Dhall        KCL    Nickel    Jsonnet  Python
      Pkl                CUE

           Compile ←────────────→ Runtime
Dhall      KCL/Pkl    Nickel    CUE    Jsonnet
```

### Expressiveness Dimension
```
           Total ←──────────────→ Turing-Complete
Dhall                      All others

           Functional ←─────────→ Object-Oriented
Jsonnet   Dhall    Nickel    KCL      Pkl
```

### Pragmatic Dimension
```
           Compiled ←───────────→ Interpreted
KCL                         Most others

           CLI-first ←──────────→ IDE-first
Dhall    Jsonnet           Pkl
```

## Key Discoveries

### 1. They're All Sugar
Every config language can be desugared to:
- Lambda calculus +
- Data literals +
- Validation predicates +
- Import mechanism

### 2. Effects Are The Differentiator
The main difference is which effects are allowed:
- **Dhall**: No effects (total)
- **Jsonnet/Ytt**: Import only (hermetic)
- **KCL/Pkl**: Controlled effects
- **Python/JS**: Full effects

### 3. Type Systems Are Pluggable
No fundamental reason a language couldn't support multiple:
- Static mode for production
- Dynamic mode for development
- Gradual for migration

### 4. Syntax Is Superficial
The same semantic program can be expressed in:
- Haskell-like (Dhall)
- Python-like (KCL)
- JSON-like (Jsonnet)
- YAML-like (Ytt)

## The Unification Hypothesis

**All configuration languages are:**
```
Surface Syntax + Type Discipline + Effect Policy + Evaluation Strategy
       ↓              ↓                ↓                ↓
   (Parser)    (Type Checker)    (Interpreter)    (Evaluator)
       ↓              ↓                ↓                ↓
       └──────────────┴────────────────┴────────────────┘
                              ↓
                    Common Core Language
                              ↓
                        JSON-like Data
```

## Practical Implications

### What This Means
1. We can build one system with pluggable components
2. Users can choose their preferred trade-offs
3. Migration between "languages" becomes configuration
4. Tooling can be shared across all variants

### What We Could Build
```yaml
# .langlang.yaml
name: my-config
base: jsonnet           # Start with Jsonnet semantics
add:
  - static-typing       # Add Dhall-like types
  - python-syntax       # Use KCL-like syntax
  - yaml-output         # Output YAML like Ytt
remove:
  - recursion          # Make it total like Dhall
```

### The Component Library
```
Parsers:     tree-sitter-{python,haskell,json,yaml,...}
Type Systems: {hindley-milner,gradual,contracts,dependent}
Validators:   {json-schema,opa,cue-unification,...}
Evaluators:   {lazy,eager,total,unification}
Interpreters: {pure,sandbox,effects}
Serializers:  {json,yaml,toml,xml,...}
```

## Conclusion

The fragmentation in configuration languages isn't due to fundamental incompatibilities - it's because each language bundles a fixed set of choices. By decomposing them into pluggable components, we can offer users the exact combination they need rather than forcing them to accept one language's entire bundle of trade-offs.