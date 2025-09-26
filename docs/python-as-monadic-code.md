# Python as Monadic Code

## The Revelation

Every line of imperative Python is just a monadic bind in disguise. Semicolons are just `>>` operators we don't write.

## Simple Example

### What You Write (Python)
```python
x = read_file("config.json")
y = json.loads(x)
z = y["database"]["host"]
print(z)
```

### What It Actually Is (Monadic)
```haskell
do
  x <- readFile "config.json"
  y <- jsonParse x
  z <- getField "database" y >>= getField "host"
  print z
```

## Mutation Is Just State Monad

### Python with Mutation
```python
x = 5
x = x + 1
if x > 5:
    y = "big"
else:
    y = "small"
```

### Desugared to State Monad
```haskell
do
  put "x" 5                    -- x = 5
  x <- get "x"                 -- read x
  put "x" (x + 1)             -- x = x + 1
  x' <- get "x"               -- read x again
  y <- if x' > 5
       then return "big"
       else return "small"
  put "y" y                   -- y = ...
```

## The Python VM IS a Monad

```haskell
-- Every Python operation runs in this monad
type PyVM a = StateT PyVMState IO a

data PyVMState = PyVMState {
  locals :: Map String PyObject,
  globals :: Map String PyObject,
  heap :: Heap,
  callStack :: [Frame],
  exceptions :: [Exception]
}
```

## Python Bytecode = Monadic Operations

```python
def f(x):
    y = x + 1
    return y * 2
```

Compiles to bytecode:
```
LOAD_FAST    0 (x)    # get "x" :: PyVM PyObject
LOAD_CONST   1 (1)    # pure 1 :: PyVM PyObject
BINARY_ADD            # liftM2 (+) :: PyVM PyObject
STORE_FAST   1 (y)    # put "y" :: PyVM ()
LOAD_FAST    1 (y)    # get "y" :: PyVM PyObject
LOAD_CONST   2 (2)    # pure 2 :: PyVM PyObject
BINARY_MUL            # liftM2 (*) :: PyVM PyObject
RETURN_VALUE          # return :: PyVM PyObject
```

## The Compiler Pattern

```racket
;; Python AST → Monadic AST
(define (python->monadic ast)
  (match ast
    [(assign var expr)
     `(>> (put ',var ,(compile expr))
          (return unit))]

    [(seq stmt1 stmt2)
     `(>> ,(python->monadic stmt1)
          ,(python->monadic stmt2))]

    [(call func args)
     `(>>= (evaluate ',func)
           (lambda (f)
             (apply f ,@(map compile args))))]

    [(if test then else)
     `(>>= ,(compile test)
           (lambda (cond)
             (if cond
                 ,(python->monadic then)
                 ,(python->monadic else))))]))
```

## Configuration Implications

This means we can write configs in Python syntax but evaluate them purely:

### Input (Python Syntax)
```python
# config.py
import os

DATABASE_HOST = os.environ.get('DB_HOST', 'localhost')
DATABASE_PORT = 5432

if PRODUCTION:
    WORKERS = 10
else:
    WORKERS = 2

config = {
    'database': {
        'host': DATABASE_HOST,
        'port': DATABASE_PORT
    },
    'workers': WORKERS
}
```

### After Monadic Compilation
```haskell
config :: ReaderT Env (State ConfigState) Value
config = do
  dbHost <- asks (lookupEnv "DB_HOST") >>= \case
    Just h -> return h
    Nothing -> return "localhost"

  let dbPort = 5432

  production <- asks (lookupEnv "PRODUCTION")
  workers <- if production
             then return 10
             else return 2

  return $ object
    [ "database" .= object
      [ "host" .= dbHost
      , "port" .= dbPort
      ]
    , "workers" .= workers
    ]
```

### Choose Your Interpreter
```python
# Pure mode (testing)
result = evaluate(config, mode='pure', env={'PRODUCTION': False})

# Sandboxed (staging)
result = evaluate(config, mode='sandbox', allowed_env=['DB_HOST'])

# Full (if you really need it)
result = evaluate(config, mode='full')
```

## The Universal Truth

**Every imperative language is monadic code where:**
- Variable assignment = State monad operations
- Sequential execution = Monadic bind (>>)
- Function calls = Monadic application
- I/O operations = IO monad effects

Python just hides the monad. Once we make it explicit, we can:
1. Control effects
2. Add types
3. Guarantee determinism
4. Enable pure evaluation
5. Choose our interpreter

## The Punchline

```
Python: x = f(); y = g(x); z = h(y)
Haskell: f >>= g >>= h
```

They're the same picture! Python is just do-notation with worse syntax.