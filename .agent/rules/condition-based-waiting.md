# Condition-Based Waiting

**Source:** [Superpowers condition-based-waiting](https://github.com/obra/superpowers/blob/main/skills/systematic-debugging/condition-based-waiting.md)

## The Problem with Timeouts

Arbitrary timeouts (`sleep 5`, `waitFor(10000`) are fragile:
- Too short → intermittent failures in CI
- Too long → slow feedback loop
- Neither tests the actual condition you care about

## The Technique

Replace timeouts with **condition polling**:

```typescript
// WRONG: Arbitrary timeout
await new Promise(r => setTimeout(r, 5000));
expect(isReady()).toBe(true);

// RIGHT: Poll the actual condition
async function waitFor(condition: () => boolean, interval = 100, maxAttempts = 50) {
  for (let i = 0; i < maxAttempts; i++) {
    if (condition()) return;
    await new Promise(r => setTimeout(r, interval));
  }
  throw new Error(`Condition not met after ${maxAttempts * interval}ms`);
}

await waitFor(() => isReady());
```

## When to Use

- Waiting for async operations to complete
- Waiting for external processes (servers, databases, workers)
- Waiting for state changes in UI or distributed systems
- Any test where "it works eventually" is the actual behavior

## Rules

- **Poll the actual condition** — Not "wait long enough"
- **Set a maximum wait time** — Still fail if the condition is never met
- **Use short intervals** — 50-200ms for most cases
- **Log on timeout** — Include the current state so debugging is possible

## Example: Server Startup

```bash
# WRONG: Sleep hoping server is ready
sleep 5
curl http://localhost:3000/health

# RIGHT: Poll until ready
for i in $(seq 1 30); do
  if curl -sf http://localhost:3000/health > /dev/null 2>&1; then
    echo "Server ready after $((i * 1))s"
    break
  fi
  sleep 1
done
```
