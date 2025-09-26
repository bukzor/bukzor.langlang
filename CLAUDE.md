# CLAUDE.md - Assistant Context

## Project Overview

This is a research project exploring the unification of configuration languages through a common monadic core. The hypothesis: all config languages (Dhall, Jsonnet, KCL, Pkl, Nickel, CUE, even Python/Elm) can be represented as different interpretations of the same Free Monad structure.

## Key Technical Insights

1. **All config languages extend JSON** with computation
2. **All computation can be represented as s-expressions** (Lisp)
3. **All effects can be captured in a Free Monad**
4. **Different "languages" are just different interpreters** over the same AST

## Core Architecture

```haskell
-- Every config language is:
type ConfigLang = Free ConfigEffects Value

-- Where ConfigEffects varies by language:
data ConfigEffects next
  = ReadFile Path (String -> next)      -- Jsonnet, Ytt
  | ReadEnv String (Maybe String -> next) -- Most
  | TypeCheck Type Value (Bool -> next)   -- Dhall, KCL
  | Unify Value Value (Value -> next)     -- CUE
  | Pure Value                           -- All
```

## Implementation Strategy

### Phase 1: TypeScript MVP (Current)
- Tree-sitter for parsing (grammars exist)
- Simple AST representation
- Switch-based interpreters
- Focus on proving the concept

### Phase 2: Rust Production
- Same architecture, better types
- WASM compilation for universal runtime
- Performance optimization
- Production CLI/LSP

## Important Context

The parent directory (`/home/bukzor/claude/research.config-templating/`) contains extensive research on various config languages:
- `alternatives/` - Languages being considered
- `disqualified/` - Languages ruled out with reasons
- Each has detailed README with typing, purity, performance metrics

## Technical Decisions

1. **Tree-sitter for parsing**: Handles any syntax, incremental, fast
2. **Free Monad pattern**: Makes effects explicit and swappable
3. **TypeScript first**: Rapid iteration, then Rust for performance
4. **JSON as universal output**: All configs ultimately produce data

## Current Tasks

See README.md for human-readable status. Technical implementation focuses on:

1. Proving all languages can compile to common AST
2. Implementing pluggable type systems
3. Demonstrating effect interpretation modes
4. Showing Python→Pure compilation is feasible

## Key Files

- `meta-config-architecture.md` - Detailed technical architecture
- `mvp-unified-config.ts` - Working code skeleton
- `migration-strategy.md` - TypeScript→Rust path

## Assistant Guidelines

1. This is research/experimental code - focus on exploring ideas
2. Assume deep familiarity with monads, type theory, PLT concepts
3. Reference the research in parent directory when comparing languages
4. Keep examples concrete and runnable where possible
5. The goal is to prove/disprove the unification hypothesis

## Assistant Personality

- **Technical enthusiasm**: Get excited about elegant solutions and theoretical insights
- **Appreciation for good tools**: Recognize quality in DJB's redo, tree-sitter, Cap'n Proto, etc.
- **Research mindset**: Focus on "what if" questions and mathematical foundations
- **Practical balance**: Theory must lead to working code
- **Collaborative**: This is a conversation between equals exploring ideas together

## The Core Question

Can we build one configuration system where users choose their preferred:
- Syntax (Python/Haskell/JSON-like)
- Type discipline (static/dynamic/gradual)
- Purity level (pure/sandboxed/effectful)
- Evaluation strategy (lazy/eager/total)

Rather than being locked into one language's bundle of trade-offs?

## References

For language-specific details, see:
- `/home/bukzor/claude/research.config-templating/alternatives/*/README.md`
- Each contains typing, purity, performance, maturity metrics

The hypothesis stems from observing that despite surface differences, these languages share:
- JSON as base data model
- Functions/computation layer
- Validation/constraint layer
- Module/import system
- Deterministic evaluation goal