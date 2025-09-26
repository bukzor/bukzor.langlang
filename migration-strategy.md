# TypeScript → Rust Migration Strategy

## Shared Resources (Write Once)

### 1. Tree-sitter Grammars
```bash
# These work with both TS and Rust
npm install tree-sitter-python tree-sitter-haskell tree-sitter-elm
# or
cargo add tree-sitter tree-sitter-python tree-sitter-haskell
```

### 2. Test Suite (JSON-based)
```json
// tests/cases.json - Works for both implementations
{
  "test_pure_dhall": {
    "input": "let x = 5 in x + 1",
    "config": {
      "syntax": "dhall",
      "purity": "pure",
      "typing": "static"
    },
    "expected": 6
  },
  "test_python_sandbox": {
    "input": "import os\nDB = os.environ.get('DB', 'localhost')",
    "config": {
      "syntax": "python",
      "purity": "sandbox"
    },
    "expected": {"DB": "localhost"}
  }
}
```

### 3. Language Server Protocol
```typescript
// Write protocol once, implement twice
interface UnifiedConfigLSP {
  initialize(): void;
  hover(pos: Position): HoverInfo;
  complete(pos: Position): CompletionItem[];
  diagnose(): Diagnostic[];
}
```

## TypeScript MVP Checklist

```typescript
// mvp.ts - Quick and dirty, get it working
✓ Parser (tree-sitter bindings)
✓ AST definition (simple tagged unions)
✓ Basic evaluator (no optimization)
✓ Effect interpreter (switch statements)
✓ JSON output
✓ CLI interface

// What we learn:
- Which features users actually want
- Performance bottlenecks
- API ergonomics
- Edge cases
```

## Rust Production Version

```rust
// src/main.rs - Production-ready
pub struct UnifiedConfig {
    parser: TreeSitterParser,
    type_checker: Box<dyn TypeChecker>,
    evaluator: Evaluator,
    serializer: Box<dyn Serializer>,
}

impl UnifiedConfig {
    pub fn new(config: Config) -> Self {
        Self {
            parser: TreeSitterParser::for_syntax(config.syntax),
            type_checker: match config.typing {
                Typing::Static => Box::new(HindleyMilner::new()),
                Typing::Gradual => Box::new(GradualChecker::new()),
                Typing::Dynamic => Box::new(NoOpChecker),
            },
            evaluator: Evaluator::new(config.evaluation, config.purity),
            serializer: Serializer::for_format(config.output),
        }
    }
}
```

## The Smart Migration Path

### Week 1: TypeScript MVP
- Get it working
- Show it to people
- Gather feedback
- Find the pain points

### Week 2-3: Rust Core
```rust
// Start with the core evaluation engine
// This is where performance matters most
mod ast;
mod eval;
mod effects;

// Can still use TypeScript for:
// - CLI (via Node FFI)
// - Web UI
// - LSP server
```

### Week 4: Full Rust
```rust
// Port everything, including:
use clap::Parser;  // CLI
use tower_lsp;      // LSP
use wasm_bindgen;   // Web bindings
```

## Hybrid Approach (Best of Both)

```json
{
  "architecture": {
    "parser": "tree-sitter (C)",
    "core": "Rust (compiled to WASM)",
    "cli": "TypeScript (better DX)",
    "lsp": "TypeScript (easier to maintain)",
    "web-playground": "TypeScript + Rust/WASM"
  }
}
```

## Key Insight

The TypeScript version isn't throwaway - it becomes:
1. The reference implementation
2. The web playground
3. The rapid prototyping environment
4. The integration test suite runner

While Rust becomes:
1. The performance-critical core
2. The WASM module
3. The CLI tool
4. The production deployment

Both versions share:
- Tree-sitter grammars
- Test cases
- Documentation
- LSP protocol definition

This way, you're not really "porting" - you're building two complementary implementations that serve different purposes.