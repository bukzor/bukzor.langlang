# Free Monads and Effect Algebras

## The Key Insight: IO Isn't Special

When you said "IO can be implemented as a Free monad", you hit on something fundamental. IO isn't magic - it's just a choice of effect algebra and interpreter.

## What Is a Free Monad?

A Free monad turns any functor into a monad. More importantly for us: **it turns a description of effects into actual effects**.

```haskell
data Free f a
  = Pure a                    -- Done, return value
  | Free (f (Free f a))       -- Effect, then continue
```

## IO as Just Another Free Monad

```haskell
-- IO is just this:
data IOF next
  = ReadFile FilePath (String -> next)
  | WriteFile FilePath String next
  | GetEnv String (Maybe String -> next)
  | Print String next
  deriving (Functor)

type IO = Free IOF

-- Your "IO" code just builds a data structure
myProgram :: IO String
myProgram = do
  content <- readFile "config.json"
  putStrLn content
  return content

-- Which is really:
myProgram =
  Free (ReadFile "config.json" $ \content ->
    Free (Print content $
      Pure content))
```

## Every Config Language's Effect Algebra

```haskell
-- Dhall: No effects
type Dhall = Free Void

-- Jsonnet: Only imports
data JsonnetF next = Import FilePath (String -> next)
type Jsonnet = Free JsonnetF

-- Nix: Derivations are effects
data NixF next
  = Import Path (String -> next)
  | Derivation Spec (StorePath -> next)
type Nix = Free NixF

-- Terraform: Resources are effects
data TerraformF next
  = CreateResource Spec (ResourceId -> next)
  | ReadState Key (Maybe Value -> next)
type Terraform = Free TerraformF

-- Python: Full PyVM operations
data PyVMF next
  = LoadName String (PyObject -> next)
  | StoreName String PyObject next
  | CallFunction PyObject [PyObject] (PyObject -> next)
type Python = Free PyVMF
```

## The Beautiful Part: Swappable Interpreters

```haskell
-- Pure interpreter (for testing)
runPure :: Free IOF a -> MockState -> a
runPure (Pure a) _ = a
runPure (Free (ReadFile path k)) state =
  runPure (k (getMockFile state path)) state
runPure (Free (Print msg k)) state =
  runPure k (addOutput state msg)

-- Sandboxed interpreter (for production configs)
runSandbox :: Free IOF a -> IO a
runSandbox (Pure a) = return a
runSandbox (Free (ReadFile path k)) =
  if isSafe path
  then readFile path >>= runSandbox . k
  else error "Access denied"
runSandbox (Free (GetEnv var k)) =
  if isAllowed var
  then lookupEnv var >>= runSandbox . k
  else runSandbox (k Nothing)

-- Real interpreter (when needed)
runReal :: Free IOF a -> IO a
runReal (Pure a) = return a
runReal (Free (ReadFile path k)) =
  readFile path >>= runReal . k
-- etc.
```

## The Configuration Unification

Every config language is just:
1. **An effect algebra** (what effects are possible)
2. **A default interpreter** (how to run those effects)

```haskell
data ConfigEffect next
  = ReadFile Path (String -> next)
  | ReadEnv String (Maybe String -> next)
  | HttpGet URL (Response -> next)
  | Import Module (Value -> next)
  | Validate Schema Value (Bool -> next)
  | Pure Value

type ConfigM = Free ConfigEffect

-- Now EVERY config language uses ConfigM
-- They just differ in:
-- 1. Which effects they allow
-- 2. How they interpret them
```

## Practical Example

```python
# This Python config...
config = {
    "db": os.environ.get("DB_HOST", "localhost"),
    "port": 5432
}
```

Becomes this Free monad structure:
```haskell
Free (ReadEnv "DB_HOST" $ \host ->
  Pure $ object
    [ "db" .= fromMaybe "localhost" host
    , "port" .= 5432
    ])
```

Which we can interpret however we want:
```haskell
-- Testing
runTest config = object ["db" .= "testdb", "port" .= 5432]

-- Sandbox
runSandbox config =
  if "DB_HOST" `elem` allowedVars
  then actuallyReadEnv
  else useDefault

-- Production
runProd config = actuallyReadEnv
```

## The Unification Theorem

**All configuration languages are isomorphic to:**
```haskell
type UniversalConfig = Free ConfigEffects Value

interpret :: InterpreterMode -> UniversalConfig -> IO Value
interpret mode config = case mode of
  Pure     -> return $ runPure config
  Sandbox  -> runSandboxed config
  Full     -> runFull config
```

The differences between Dhall, Jsonnet, KCL, Python configs, etc. are just:
1. **Syntax** (parsed away)
2. **Effect algebra subset** (which ConfigEffects they use)
3. **Default interpreter** (Pure vs Sandbox vs Full)

## The Punchline

When you said "IO can be implemented as a Free monad", you discovered that:
- **No language feature is "special"**
- **Everything is just data + interpreters**
- **Any effect system can be embedded in any language**
- **The "language" is just choosing defaults**

This is why we can unify all config languages - they're all just different default choices over the same Free monad pattern!