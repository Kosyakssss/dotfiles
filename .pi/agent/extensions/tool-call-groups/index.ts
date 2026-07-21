import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { ToolExecutionComponent } from "@earendil-works/pi-coding-agent";
import { Box, Container, Text, type Component } from "@earendil-works/pi-tui";

const PATCH_KEY = Symbol.for("kote.pi-tool-call-groups.patch.v1");
const DISPLAY_TEXT = "displayText";
const DISPLAY_TEXT_SCHEMA = {
  type: "string",
  minLength: 4,
  maxLength: 120,
  description:
    "Short present-tense account of what this call is meant to achieve, shown to the user after the call finishes streaming. Start with a verb and use 4-12 words.",
};

type ThemeLike = {
  fg(color: string, text: string): string;
  bg(color: string, text: string): string;
  bold(text: string): string;
};

type ToolResultLike = {
  content?: Array<{ type?: string; text?: string; mimeType?: string }>;
  details?: unknown;
  isError?: boolean;
};

type ToolComponentLike = {
  toolName: string;
  toolCallId: string;
  args: Record<string, unknown>;
  expanded: boolean;
  isPartial: boolean;
  executionStarted: boolean;
  argsComplete: boolean;
  result?: ToolResultLike;
  resultRendererComponent?: Component;
  imageComponents?: Component[];
  ui?: { requestRender(): void };
  setExpanded(expanded: boolean): void;
};

type ObjectSchema = {
  properties?: Record<string, unknown>;
  required?: unknown;
  [key: string]: unknown;
};

type SchemaSnapshot = {
  schema: ObjectSchema;
  properties: Record<string, unknown>;
  hadDisplayText: boolean;
  displayTextValue?: unknown;
  hadRequired: boolean;
  requiredValue?: unknown;
};

type PatchState = {
  owner: object;
  originalContainerRender: (this: Container, width: number) => string[];
};

type GlobalWithPatch = typeof globalThis & {
  [PATCH_KEY]?: PatchState;
};

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function safeStringify(value: unknown, space = 2): string {
  const seen = new WeakSet<object>();
  try {
    return JSON.stringify(
      value,
      (_key, item: unknown) => {
        if (typeof item === "bigint") return `${item}n`;
        if (item !== null && typeof item === "object") {
          if (seen.has(item)) return "[Circular]";
          seen.add(item);
        }
        return item;
      },
      space,
    ) ?? String(value);
  } catch {
    return String(value);
  }
}

function oneLine(value: unknown, limit = 120): string {
  const raw = typeof value === "string" ? value : safeStringify(value, 0);
  const compact = raw.replace(/\s+/g, " ").trim();
  return compact.length <= limit ? compact : `${compact.slice(0, limit - 1)}…`;
}

function displayTextFor(component: ToolComponentLike): string {
  const value = component.args?.[DISPLAY_TEXT];
  if (typeof value === "string" && value.trim()) return value.trim();
  return `Run ${component.toolName}`;
}

function isComplete(component: ToolComponentLike, completedCalls: Set<string>): boolean {
  return (
    completedCalls.has(component.toolCallId) ||
    component.argsComplete ||
    component.executionStarted ||
    component.result !== undefined
  );
}

function statusFor(component: ToolComponentLike, theme: ThemeLike): string {
  if (component.result?.isError) return theme.fg("error", "×");
  if (component.isPartial || component.result === undefined) return theme.fg("warning", "●");
  return theme.fg("success", "✓");
}

function summarizeArguments(args: Record<string, unknown>): string {
  const entries = Object.entries(args).filter(([key]) => key !== DISPLAY_TEXT);
  if (entries.length === 0) return "no arguments";
  return entries
    .slice(0, 4)
    .map(([key, value]) => `${key}=${oneLine(value, 56)}`)
    .join(" · ") + (entries.length > 4 ? ` · +${entries.length - 4} more` : "");
}

function resultText(result: ToolResultLike | undefined): string {
  if (!result) return "";
  const parts: string[] = [];
  for (const block of result.content ?? []) {
    if (block.type === "text" && typeof block.text === "string") {
      parts.push(block.text);
    } else if (block.type === "image") {
      parts.push(`[image${block.mimeType ? `: ${block.mimeType}` : ""}]`);
    }
  }
  return parts.join("\n");
}

function renderToolLines(
  component: ToolComponentLike,
  level: number,
  completedCalls: Set<string>,
  theme: ThemeLike,
): string {
  const status = statusFor(component, theme);
  const complete = isComplete(component, completedCalls);

  if (!complete) {
    const title = `${status} ${theme.fg("toolTitle", theme.bold(component.toolName))}`;
    return `${title}\n${theme.fg("toolOutput", safeStringify(component.args))}`;
  }

  const summary = `${status} ${theme.fg("toolTitle", displayTextFor(component))}`;
  if (level === 0) return summary;

  if (level === 1) {
    const detail = `${component.toolName} · ${summarizeArguments(component.args)}`;
    const output = oneLine(resultText(component.result), 160);
    return `${summary}\n  ${theme.fg("dim", detail + (output ? ` · ${output}` : ""))}`;
  }

  const sections = [
    summary,
    theme.fg("dim", `${component.toolName} input`),
    theme.fg("toolOutput", safeStringify(component.args)),
  ];
  if (!component.resultRendererComponent) {
    const output = resultText(component.result);
    const details = component.result?.details;
    if (output) {
      sections.push(theme.fg("dim", "result"), theme.fg("toolOutput", output));
    }
    if (details !== undefined) {
      sections.push(theme.fg("dim", "details"), theme.fg("toolOutput", safeStringify(details)));
    }
  }
  return sections.join("\n");
}

function groupBackground(components: ToolComponentLike[]): "toolPendingBg" | "toolErrorBg" | "toolSuccessBg" {
  if (components.some((component) => component.isPartial || component.result === undefined)) {
    return "toolPendingBg";
  }
  if (components.some((component) => component.result?.isError)) return "toolErrorBg";
  return "toolSuccessBg";
}

function renderToolGroup(
  components: ToolComponentLike[],
  width: number,
  level: number,
  completedCalls: Set<string>,
  theme: ThemeLike,
): string[] {
  const box = new Box(1, 1, (text) => theme.bg(groupBackground(components), text));
  const content = new Container();
  for (const component of components) {
    content.addChild(new Text(renderToolLines(component, level, completedCalls, theme), 0, 0));
    if (level === 2 && component.resultRendererComponent) {
      content.addChild(component.resultRendererComponent);
    }
  }
  box.addChild(content);

  const lines = ["", ...box.render(width)];
  if (level === 2) {
    for (const component of components) {
      for (const image of component.imageComponents ?? []) {
        lines.push("", ...image.render(width));
      }
    }
  }
  return lines;
}

type RenderPatchHandle = {
  dispose(): void;
  requestRender(): void;
  setExpanded(expanded: boolean): void;
};

function installRenderPatch(
  owner: object,
  getTheme: () => ThemeLike | undefined,
  getLevel: () => number,
  completedCalls: Set<string>,
): RenderPatchHandle | undefined {
  const globalWithPatch = globalThis as GlobalWithPatch;
  if (globalWithPatch[PATCH_KEY]) return undefined;

  const originalContainerRender = Container.prototype.render;
  const seenTools = new Set<ToolComponentLike>();
  let requestRender: (() => void) | undefined;

  Container.prototype.render = function groupedContainerRender(width: number): string[] {
    const theme = getTheme();
    const children = this.children;
    if (!theme || !children.some((child) => child instanceof ToolExecutionComponent)) {
      return originalContainerRender.call(this, width);
    }

    const lines: string[] = [];
    let pendingTools: ToolComponentLike[] = [];

    const flushTools = (): void => {
      if (pendingTools.length === 0) return;
      lines.push(...renderToolGroup(pendingTools, width, getLevel(), completedCalls, theme));
      pendingTools = [];
    };

    for (const child of children) {
      if (child instanceof ToolExecutionComponent) {
        const tool = child as unknown as ToolComponentLike;
        pendingTools.push(tool);
        seenTools.add(tool);
        if (getLevel() === 2 && !tool.expanded) tool.setExpanded(true);
        if (tool.ui?.requestRender) {
          requestRender = () => tool.ui?.requestRender();
        }
        continue;
      }

      const childLines = child.render(width);
      if (pendingTools.length > 0 && childLines.length === 0) {
        // A tool-only assistant message renders no lines. Ignore it so calls on
        // either side remain one group until visible assistant text appears.
        continue;
      }

      flushTools();
      lines.push(...childLines);
    }

    flushTools();
    return lines;
  };

  globalWithPatch[PATCH_KEY] = { owner, originalContainerRender };

  return {
    dispose() {
      const current = globalWithPatch[PATCH_KEY];
      if (current?.owner !== owner) return;
      Container.prototype.render = current.originalContainerRender;
      delete globalWithPatch[PATCH_KEY];
      seenTools.clear();
      requestRender = undefined;
    },
    requestRender() {
      requestRender?.();
    },
    setExpanded(expanded: boolean) {
      for (const tool of seenTools) tool.setExpanded(expanded);
    },
  };
}

function addDisplayTextToSchema(
  schemaValue: unknown,
  snapshots: SchemaSnapshot[],
): boolean {
  const schema = asRecord(schemaValue) as ObjectSchema;
  const properties = asRecord(schema.properties);
  if (schema.type !== "object" || Object.keys(properties).length === 0) return false;

  const hadDisplayText = Object.prototype.hasOwnProperty.call(properties, DISPLAY_TEXT);
  if (hadDisplayText) return false;

  snapshots.push({
    schema,
    properties,
    hadDisplayText,
    displayTextValue: properties[DISPLAY_TEXT],
    hadRequired: Object.prototype.hasOwnProperty.call(schema, "required"),
    requiredValue: schema.required,
  });

  properties[DISPLAY_TEXT] = { ...DISPLAY_TEXT_SCHEMA };
  const required = Array.isArray(schema.required)
    ? schema.required.filter((item): item is string => typeof item === "string")
    : [];
  schema.required = [...required, DISPLAY_TEXT];
  return true;
}

function restoreSchemas(snapshots: SchemaSnapshot[]): void {
  for (const snapshot of snapshots.reverse()) {
    if (snapshot.hadDisplayText) {
      snapshot.properties[DISPLAY_TEXT] = snapshot.displayTextValue;
    } else {
      delete snapshot.properties[DISPLAY_TEXT];
    }
    if (snapshot.hadRequired) {
      snapshot.schema.required = snapshot.requiredValue;
    } else {
      delete snapshot.schema.required;
    }
  }
  snapshots.length = 0;
}

export default function toolCallGroups(pi: ExtensionAPI): void {
  const owner = {};
  const completedCalls = new Set<string>();
  const snapshots: SchemaSnapshot[] = [];
  const decoratedSchemas = new WeakSet<object>();
  const schemasWithInjectedDisplayText = new WeakSet<object>();
  const decoratedSchemaByToolName = new Map<string, object>();
  let activeTheme: ThemeLike | undefined;
  let expansionLevel = 0;

  const decorateKnownTools = (): void => {
    let tools: ReturnType<ExtensionAPI["getAllTools"]>;
    try {
      tools = pi.getAllTools();
    } catch {
      return;
    }

    for (const tool of tools) {
      if (!tool.parameters || typeof tool.parameters !== "object") continue;
      const schema = tool.parameters as object;
      if (!decoratedSchemas.has(schema)) {
        decoratedSchemas.add(schema);
        if (addDisplayTextToSchema(tool.parameters, snapshots)) {
          schemasWithInjectedDisplayText.add(schema);
        }
      }

      if (schemasWithInjectedDisplayText.has(schema)) {
        decoratedSchemaByToolName.set(tool.name, schema);
      } else if (decoratedSchemaByToolName.get(tool.name) !== schema) {
        decoratedSchemaByToolName.delete(tool.name);
      }
    }
  };

  const renderPatch = installRenderPatch(
    owner,
    () => activeTheme,
    () => expansionLevel,
    completedCalls,
  );

  pi.registerShortcut("alt+o", {
    description: "Expand grouped tool calls",
    handler: async () => {
      expansionLevel = Math.min(2, expansionLevel + 1);
      renderPatch?.setExpanded(expansionLevel === 2);
      renderPatch?.requestRender();
    },
  });

  pi.registerShortcut("alt+i", {
    description: "Collapse grouped tool calls",
    handler: async () => {
      expansionLevel = Math.max(0, expansionLevel - 1);
      renderPatch?.setExpanded(expansionLevel === 2);
      renderPatch?.requestRender();
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    activeTheme = ctx.ui.theme as unknown as ThemeLike;
    completedCalls.clear();
    decorateKnownTools();
  });

  pi.on("before_agent_start", async () => {
    decorateKnownTools();
  });

  pi.on("message_update", async (event) => {
    if (event.message.role !== "assistant") return;
    const streamEvent = event.assistantMessageEvent;
    if (streamEvent.type === "toolcall_end") {
      completedCalls.add(streamEvent.toolCall.id);
    }
  });

  pi.on("message_end", async (event) => {
    if (event.message.role !== "assistant") return;
    for (const content of event.message.content) {
      if (content.type === "toolCall") completedCalls.add(content.id);
    }
  });

  pi.on("tool_call", async (event) => {
    if (!decoratedSchemaByToolName.has(event.toolName)) return;
    // Validation has already run. Pi guarantees that tool_call mutations are
    // passed to execute without another validation pass, while the assistant
    // message keeps the original arguments for rendering and session replay.
    delete (event.input as Record<string, unknown>)[DISPLAY_TEXT];
  });

  pi.on("tool_result", async () => {
    // Tools may register more tools during execution.
    decorateKnownTools();
  });

  pi.on("session_shutdown", async () => {
    renderPatch?.dispose();
    restoreSchemas(snapshots);
    activeTheme = undefined;
    completedCalls.clear();
  });
}
