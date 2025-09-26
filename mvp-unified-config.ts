#!/usr/bin/env tsx

/**
 * Unified Configuration Language - MVP
 * Supports: Dhall-like, Jsonnet-like, Python-like configs
 */

import Parser from 'tree-sitter';
import Python from 'tree-sitter-python';
// import Haskell from 'tree-sitter-haskell';  // for Dhall
// import Json from 'tree-sitter-json';        // for Jsonnet

// ============================================================================
// Core AST - Everything compiles to this
// ============================================================================

type AST =
  | { tag: 'lit', value: any }
  | { tag: 'var', name: string }
  | { tag: 'lambda', params: string[], body: AST }
  | { tag: 'apply', func: AST, args: AST[] }
  | { tag: 'let', name: string, value: AST, body: AST }
  | { tag: 'object', fields: Record<string, AST> }
  | { tag: 'array', items: AST[] }
  | { tag: 'if', cond: AST, then: AST, else: AST }
  | { tag: 'binop', op: string, left: AST, right: AST }
  | { tag: 'access', object: AST, field: string }
  | { tag: 'effect', effect: Effect, cont: (result: any) => AST }

// ============================================================================
// Effects as Data
// ============================================================================

type Effect =
  | { type: 'readFile', path: string }
  | { type: 'readEnv', var: string }
  | { type: 'httpGet', url: string }

type Config = {
  syntax: 'dhall' | 'jsonnet' | 'python' | 'elm'
  typing: 'static' | 'dynamic' | 'gradual'
  purity: 'pure' | 'sandbox' | 'full'
  evaluation: 'eager' | 'lazy'
}

// ============================================================================
// Parser: Source -> AST (using tree-sitter)
// ============================================================================

function parseSource(source: string, syntax: Config['syntax']): AST {
  // Tree-sitter does the hard work
  const parser = new Parser();

  switch(syntax) {
    case 'python':
      parser.setLanguage(Python);
      break;
    // ... other languages
  }

  const tree = parser.parse(source);
  return treeToAST(tree.rootNode);
}

function treeToAST(node: any): AST {
  // Convert tree-sitter AST to our unified AST
  switch(node.type) {
    case 'assignment':
      return {
        tag: 'let',
        name: node.childForFieldName('left').text,
        value: treeToAST(node.childForFieldName('right')),
        body: treeToAST(node.nextSibling)
      };
    case 'if_statement':
      return {
        tag: 'if',
        cond: treeToAST(node.childForFieldName('condition')),
        then: treeToAST(node.childForFieldName('consequence')),
        else: treeToAST(node.childForFieldName('alternative'))
      };
    // ... etc
    default:
      return { tag: 'lit', value: null };
  }
}

// ============================================================================
// Type Checker (Optional)
// ============================================================================

type Type =
  | { tag: 'tvar', name: string }
  | { tag: 'tint' }
  | { tag: 'tstring' }
  | { tag: 'tbool' }
  | { tag: 'tarray', elem: Type }
  | { tag: 'tobject', fields: Record<string, Type> }
  | { tag: 'tfunc', params: Type[], ret: Type }

function typecheck(ast: AST, config: Config): AST {
  if (config.typing === 'dynamic') return ast;

  // Simple bidirectional type checking
  // ... 200 lines of code

  return ast;
}

// ============================================================================
// Evaluator with Effect Interpretation
// ============================================================================

type Value =
  | number | string | boolean | null
  | Value[]
  | { [key: string]: Value }
  | { tag: 'closure', params: string[], body: AST, env: Env }

type Env = Map<string, Value>;

function evaluate(ast: AST, env: Env, config: Config): Value {
  switch(ast.tag) {
    case 'lit':
      return ast.value;

    case 'var':
      return env.get(ast.name) ?? error(`Undefined: ${ast.name}`);

    case 'lambda':
      return { tag: 'closure', params: ast.params, body: ast.body, env };

    case 'apply':
      const func = evaluate(ast.func, env, config);
      if (func.tag !== 'closure') error('Not a function');
      const args = ast.args.map(a => evaluate(a, env, config));
      const newEnv = new Map(func.env);
      func.params.forEach((p, i) => newEnv.set(p, args[i]));
      return evaluate(func.body, newEnv, config);

    case 'let':
      const val = evaluate(ast.value, env, config);
      const newEnv2 = new Map(env);
      newEnv2.set(ast.name, val);
      return evaluate(ast.body, newEnv2, config);

    case 'if':
      const cond = evaluate(ast.cond, env, config);
      return cond ? evaluate(ast.then, env, config)
                  : evaluate(ast.else, env, config);

    case 'object':
      const obj: any = {};
      for (const [k, v] of Object.entries(ast.fields)) {
        obj[k] = evaluate(v, env, config);
      }
      return obj;

    case 'effect':
      return interpretEffect(ast.effect, ast.cont, env, config);

    // ... other cases
  }

  return null;
}

function interpretEffect(effect: Effect, cont: Function, env: Env, config: Config): Value {
  switch(config.purity) {
    case 'pure':
      // Mock all effects
      switch(effect.type) {
        case 'readFile':
          return cont('{"mocked": true}');
        case 'readEnv':
          return cont('test');
        default:
          error('Effect not allowed in pure mode');
      }

    case 'sandbox':
      // Allow some effects
      switch(effect.type) {
        case 'readFile':
          if (!effect.path.startsWith('/config/')) {
            error('Can only read from /config/');
          }
          // Actually read file
          return cont(require('fs').readFileSync(effect.path, 'utf8'));
        case 'readEnv':
          return cont(process.env[effect.var]);
        case 'httpGet':
          error('Network not allowed in sandbox');
      }

    case 'full':
      // Allow everything
      // ... actual implementation
  }
}

// ============================================================================
// CLI Interface
// ============================================================================

function unifiedConfig(source: string, config: Config): any {
  // 1. Parse
  const ast = parseSource(source, config.syntax);

  // 2. Typecheck (optional)
  const typed = typecheck(ast, config);

  // 3. Evaluate
  const result = evaluate(typed, new Map(), config);

  // 4. Output
  return result;
}

// ============================================================================
// Usage Examples
// ============================================================================

// Dhall-like (pure, typed)
const dhallResult = unifiedConfig(`
  let database = {
    host = "localhost",
    port = 5432
  }
  in database
`, {
  syntax: 'dhall',
  typing: 'static',
  purity: 'pure',
  evaluation: 'lazy'
});

// Python-like (dynamic, sandboxed)
const pythonResult = unifiedConfig(`
  import os
  DATABASE_HOST = os.environ.get('DB_HOST', 'localhost')
  config = {
    'database': {
      'host': DATABASE_HOST,
      'port': 5432
    }
  }
`, {
  syntax: 'python',
  typing: 'dynamic',
  purity: 'sandbox',
  evaluation: 'eager'
});

// Jsonnet-like (dynamic, pure)
const jsonnetResult = unifiedConfig(`
  local database = {
    host: "localhost",
    port: if std.env("PROD") then 5432 else 1234
  };

  {
    database: database,
    replicas: [database { host: "replica" + i } for i in [1,2,3]]
  }
`, {
  syntax: 'jsonnet',
  typing: 'dynamic',
  purity: 'pure',
  evaluation: 'lazy'
});

console.log(JSON.stringify(dhallResult, null, 2));

// ============================================================================
// The key insight: All config languages are the same pattern with different:
// 1. Syntax (handled by tree-sitter)
// 2. Type checking rules (pluggable)
// 3. Effect interpretation (pluggable)
// 4. Evaluation strategy (pluggable)
// ============================================================================

function error(msg: string): never {
  throw new Error(msg);
}