---
name: speckit-converge
description: "Assess the current codebase against the feature's spec, plan, and tasks, then append any remaining unbuilt work as new tasks to tasks.md so implement can complete it."
user-invocable: true
disable-model-invocation: true
---

Delegates the workflow to the custom agent **speckit.converge**, defined in
`.github/agents/speckit.converge.agent.md`.

To run from a terminal:

    copilot --agent speckit.converge --prompt "<user input>"

When invoked inside a Copilot session, pass the user input from the
invoking message to the named custom agent and relay its result. If the
custom agent is unavailable, read `.github/agents/speckit.converge.agent.md` and follow its
instructions inline.
