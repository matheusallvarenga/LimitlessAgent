# Example: Simple Goal

This example demonstrates using Limitless Agent for a straightforward task.

---

## Goal

```
List all Python files in the project and count the total lines of code
```

## Command

```bash
./scripts/limitless.sh run "List all Python files in the project and count the total lines of code"
```

---

## Execution Flow

### 1. Goal Analysis

Limitless Agent analyzes the goal:

```
Complexity Score: 0.25 (SIMPLE)
Estimated Iterations: 1-2
Recommended Model: Claude Haiku
Agents Needed: None (direct execution)
```

### 2. Iteration 1

**Action**: Execute file listing and counting

```bash
find . -name "*.py" -type f | wc -l
find . -name "*.py" -type f -exec wc -l {} + | tail -1
```

**Result**:
```
Files found: 23
Total lines: 4,521
```

### 3. Completion Check

Goal achieved in 1 iteration.

---

## Output

```
[INFO] Starting Limitless execution
[INFO] Execution ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
[INFO] Goal: List all Python files in the project and count the total lines of code
[INFO] Max Iterations: 100

[INFO] Iteration 1/100
[SUCCESS] Goal completed at iteration 1

## Summary

**Python Files Found**: 23
**Total Lines of Code**: 4,521

### File Breakdown
| File | Lines |
|------|-------|
| src/main.py | 245 |
| src/utils/helper.py | 128 |
| src/core/engine.py | 456 |
| ... | ... |

---

[SUCCESS] Limitless execution completed successfully
Duration: 12 seconds
Tokens used: 1,234
Cost: $0.0003
```

---

## Notifications

### Slack

```
:rocket: Task Started
Goal: List all Python files in the project and count the total lines of code
Execution ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
Time: 2026-01-11T20:00:00Z
```

```
:white_check_mark: Task Completed
Goal: List all Python files in the project and count the total lines of code
Duration: 1 iteration
Iterations: 1
```

---

## Key Takeaways

1. **Simple tasks** use Claude Haiku for cost efficiency
2. **Direct execution** when no specialized agent needed
3. **Single iteration** for straightforward goals
4. **Low cost** (~$0.0003) for simple queries

---

## Try It Yourself

```bash
# Clone the repo
git clone https://github.com/matheusallvarenga/limitless-agent.git
cd limitless-agent

# Run the example
./scripts/limitless.sh run "List all Python files in the project and count the total lines of code"
```
