# LangLang: A Unified Configuration Language

> "Every configuration language is just choosing different trade-offs. What if we could choose our own?"

## What is this?

LangLang is an experiment in unifying configuration languages (Dhall, Jsonnet, KCL, Pkl, Nickel, CUE, etc.) into a single composable system where you can pick your trade-offs:

- **Want Python syntax with Dhall's type safety?** ✓
- **Want Jsonnet's hermetic evaluation with gradual typing?** ✓
- **Want Elm's purity with YAML output?** ✓

## The Core Insight

All configuration languages compile down to the same thing: data structures (usually JSON). They differ only in:

1. **Syntax** (Python-like, Haskell-like, JSON-like)
2. **Type System** (static, dynamic, gradual)
3. **Evaluation** (lazy, eager, total)
4. **Effects** (pure, sandboxed, unrestricted)

So why not make these pluggable?

## Quick Example

```typescript
// Choose your configuration style
const config = unifiedConfig(source, {
  syntax: 'python',      // Python-like syntax
  typing: 'gradual',     // Types when you want them
  purity: 'sandbox',     // Limited side effects
  evaluation: 'lazy'     // Evaluate only what's needed
});
```

## How It Works

```
Any Syntax → Parser → Universal AST → Type Check → Evaluate → JSON/YAML
                ↑                          ↑           ↑
                |                          |           |
          Tree-sitter              Pluggable    Pluggable
          (C library)              Component     Interpreter
```

Every configuration language becomes a Free Monad over a common effect algebra. Even imperative Python can be compiled to pure functional code!

## Project Structure

- `meta-config-architecture.md` - The theoretical foundation
- `mvp-unified-config.ts` - TypeScript proof of concept
- `migration-strategy.md` - Path from prototype to production

## Status

🔬 **Research Phase** - Exploring the theoretical foundations and building proof of concepts.

## The Vision

Instead of learning 10 different configuration languages, learn one system that can behave like any of them - or like your ideal combination.

## Contributing

This is an open exploration. Ideas, critiques, and "what-ifs" are welcome!

## Key Questions We're Exploring

1. Can all config languages be reduced to a common core?
2. Is a "meta-configuration language" practical or just academically interesting?
3. What's the minimum viable unification?
4. Could this solve the configuration fragmentation problem?

## Related Work

- [Dhall](https://dhall-lang.org/) - Total functional configuration
- [Jsonnet](https://jsonnet.org/) - Data templating language
- [KCL](https://www.kcl-lang.io/) - Constraint-based configuration
- [Nickel](https://nickel-lang.org/) - Gradual typing for configuration
- [CUE](https://cuelang.org/) - Validate, define, and use configuration

## License

MIT - This is research code, use at your own risk!

---

*"All configuration languages are just monadic interpreters over the configuration monad. Once you see it, you can't unsee it."*