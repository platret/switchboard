import type { HookCallback, Options, SettingSource } from '@anthropic-ai/claude-agent-sdk'
import type { Agent, ApprovalDecision, Project, Role } from '@switchboard/shared'

const strippedEnvKeys = ['ANTHROPIC_API_KEY', 'ANTHROPIC_AUTH_TOKEN']
const hostOnlyPrefix = 'SWITCHBOARD_'
const approvalHookTimeoutSeconds = 660

export type ToolCall = {
  toolUseId: string
  toolName: string
  input: unknown
  signal: AbortSignal
  prompted: boolean
}

export type Verdict = {
  decision: ApprovalDecision
  asked: boolean
  reason: string
}

export type OptionsInput = {
  agent: Agent
  project: Project
  role: Role
  settingSources: SettingSource[]
  protectedPaths: string[]
  authorize: (call: ToolCall) => Promise<Verdict>
  onStderr: (data: string) => void
}

function childEnv(): Record<string, string | undefined> {
  return Object.fromEntries(Object.entries(process.env).filter(([key]) => !key.startsWith(hostOnlyPrefix) && !strippedEnvKeys.includes(key)))
}

export function buildOptions({ agent, project, role, settingSources, protectedPaths, authorize, onStderr }: OptionsInput): Options {
  const gate: HookCallback = async (input, _toolUseId, { signal }) => {
    if (input.hook_event_name !== 'PreToolUse') return {}
    const verdict = await authorize({ toolUseId: input.tool_use_id, toolName: input.tool_name, input: input.tool_input, signal, prompted: false })
    if (!verdict.asked) return {}
    return { hookSpecificOutput: { hookEventName: 'PreToolUse', permissionDecision: verdict.decision, permissionDecisionReason: verdict.reason } }
  }

  return {
    cwd: project.path,
    additionalDirectories: project.additionalDirectories,
    env: childEnv(),
    permissionMode: 'default',
    settingSources,
    settings: {
      disableSkillShellExecution: true,
      permissions: {
        disableBypassPermissionsMode: 'disable',
        disableAutoMode: 'disable',
        deny: protectedPaths.map((path) => `Read(/${path})`),
      },
    },
    includePartialMessages: true,
    systemPrompt: { type: 'preset', preset: 'claude_code', append: role.systemPrompt },
    tools: role.tools,
    model: role.model,
    resume: agent.sessionId ?? undefined,
    hooks: { PreToolUse: [{ hooks: [gate], timeout: approvalHookTimeoutSeconds, onFailure: 'block' }] },
    canUseTool: async (toolName, input, { toolUseID, signal }) => {
      const verdict = await authorize({ toolUseId: toolUseID, toolName, input, signal, prompted: true })
      return verdict.decision === 'allow' ? { behavior: 'allow', updatedInput: input } : { behavior: 'deny', message: verdict.reason }
    },
    stderr: onStderr,
  }
}
