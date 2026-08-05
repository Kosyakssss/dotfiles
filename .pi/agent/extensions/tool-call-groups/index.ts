import { homedir } from "node:os";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { ToolExecutionComponent } from "@earendil-works/pi-coding-agent";
import {
  Box,
  Container,
  Text,
  truncateToWidth,
  wrapTextWithAnsi,
  type Component,
} from "@earendil-works/pi-tui";

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
  return webToolTitle(component.toolName) ?? `Run ${component.toolName}`;
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
  if (component.isPartial || component.result === undefined) return theme.fg("accent", "●");
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

function toolTitle(component: ToolComponentLike, theme: ThemeLike): string {
  return `${statusFor(component, theme)} ${theme.fg("toolTitle", displayTextFor(component))}`;
}

function isToolComponent(component: Component): component is Component & ToolComponentLike {
  const value = component as Component & Partial<ToolComponentLike>;
  return (
    component instanceof ToolExecutionComponent ||
    (typeof value.toolName === "string" &&
      typeof value.toolCallId === "string" &&
      value.args !== null &&
      typeof value.args === "object" &&
      typeof value.setExpanded === "function")
  );
}

function isBoxShell(component: Component): component is Component & { children: Component[] } {
  const value = component as Component & {
    children?: unknown;
    paddingX?: unknown;
    paddingY?: unknown;
  };
  return (
    component.constructor?.name === "Box" &&
    Array.isArray(value.children) &&
    typeof value.paddingX === "number" &&
    typeof value.paddingY === "number"
  );
}

class ShelllessResult implements Component {
  constructor(private readonly component: Component) {}

  render(width: number): string[] {
    if (!isBoxShell(this.component)) return this.component.render(width);
    return this.component.children.flatMap((child) => child.render(width));
  }

  invalidate(): void {
    this.component.invalidate();
  }
}

function outputPadding(children: Component[]): 0 | 1 | undefined {
  for (const child of children) {
    const value = (child as Component & { outputPad?: unknown }).outputPad;
    if (value === 0 || value === 1) return value;
  }
  return undefined;
}

function plainBlock(
  title: string,
  body: string[],
  width: number,
  padding: 0 | 1,
  _theme?: ThemeLike,
): string[] {
  const sidePadding = " ".repeat(padding);
  const contentWidth = Math.max(1, width - padding * 2);
  const lines: string[] = [];
  if (title) lines.push(`${sidePadding}${truncateToWidth(title, contentWidth, "")}`);
  for (const line of body.length > 0 ? body : [""]) {
    lines.push(`${sidePadding}${truncateToWidth(line, contentWidth, "")}`);
  }
  return lines;
}

function messageText(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .map((part) => {
      if (!part || typeof part !== "object") return "";
      const value = part as { type?: string; text?: string };
      return value.type === "text" && typeof value.text === "string" ? value.text : "";
    })
    .filter(Boolean)
    .join("\n");
}

function webMessageTitle(customType: string, theme: ThemeLike): string {
  if (customType === "web-search-error") {
    return `${theme.fg("error", "×")} ${theme.fg("customMessageLabel", "web search · error")}`;
  }
  if (customType === "web-search-content-ready") {
    return `${theme.fg("success", "✓")} ${theme.fg("customMessageLabel", "web search · content ready")}`;
  }
  if (customType === "google-account") {
    return `${theme.fg("accent", "◆")} ${theme.fg("customMessageLabel", "google · account")}`;
  }
  if (customType === "curator-config") {
    return `${theme.fg("accent", "◆")} ${theme.fg("customMessageLabel", "web search · curator")}`;
  }
  return `${theme.fg("success", "✓")} ${theme.fg("customMessageLabel", "web search · results")}`;
}

function renderWebMessage(
  customType: string,
  content: unknown,
  width: number,
  outputPad: number,
  theme: ThemeLike,
): string[] {
  const padding = outputPad === 0 ? 0 : 1;
  const body = messageText(content).split("\n").map((line) => {
    if (customType === "web-search-error") return theme.fg("error", line);
    return theme.fg("customMessageText", line);
  });
  return plainBlock(
    webMessageTitle(customType, theme),
    wrapPlainBody(body, width, padding),
    width,
    padding,
    theme,
  );
}

function webToolTitle(toolName: string): string | undefined {
  return {
    web_search: "Search the web",
    source_check: "Check source",
    fetch_content: "Fetch content",
    get_search_content: "Get search content",
  }[toolName];
}

function wrapPlainBody(lines: string[], width: number, padding: 0 | 1): string[] {
  const contentWidth = Math.max(1, width - padding * 2);
  return lines.flatMap((line) => line ? wrapTextWithAnsi(line, contentWidth) : [""]);
}

function workflowResultDisplay(content: string, theme: ThemeLike): { title: string; lines: string[] } {
  const normalized = content.replaceAll(homedir(), "~");
  const match = normalized.match(/^✓ Background workflow "([^"]+)" finished \(([^)]+)\)\.\s*/);
  const name = (match?.[1] ?? "completed").replaceAll("_", " ");
  const title = `${theme.fg("success", "✓")} ${theme.fg("customMessageLabel", `workflow · ${name}`)}`;
  const rest = match ? normalized.slice(match[0].length).trim() : normalized.trim();
  const lines = rest.split("\n").map((line) => {
    if (line.startsWith("↳ Full result:")) return theme.fg("dim", line);
    return theme.fg("customMessageText", line);
  });
  if (match?.[2]) lines.unshift(theme.fg("dim", match[2]), "");
  return { title, lines };
}

function expandedToolBody(
  component: ToolComponentLike,
  width: number,
  theme: ThemeLike,
): string[] {
  const content = new Container();
  const args = { ...component.args };
  delete args[DISPLAY_TEXT];
  content.addChild(
    new Text(
      `${theme.fg("dim", `${component.toolName} input`)}\n${theme.fg("toolOutput", safeStringify(args))}`,
      0,
      0,
    ),
  );

  if (component.resultRendererComponent) {
    content.addChild(new ShelllessResult(component.resultRendererComponent));
  } else {
    const output = resultText(component.result);
    const details = component.result?.details;
    if (output) {
      content.addChild(
        new Text(`${theme.fg("dim", "result")}\n${theme.fg("toolOutput", output)}`, 0, 0),
      );
    }
    if (details !== undefined) {
      content.addChild(
        new Text(
          `${theme.fg("dim", "details")}\n${theme.fg("toolOutput", safeStringify(details))}`,
          0,
          0,
        ),
      );
    }
  }
  return content.render(width);
}

function groupBackground(
  components: ToolComponentLike[],
): "toolPendingBg" | "toolErrorBg" | "toolSuccessBg" {
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
  padding: 0 | 1,
): string[] {
  const content = new Container();
  const bodyWidth = Math.max(1, width - padding * 2);

  for (const [index, component] of components.entries()) {
    if (index > 0) content.addChild(new Text("", 0, 0));
    const lines = [toolTitle(component, theme)];

    if (level === 1) {
      const complete = isComplete(component, completedCalls);
      const detail = complete
        ? `${component.toolName} · ${summarizeArguments(component.args)}`
        : `${component.toolName} · preparing input`;
      const output = oneLine(resultText(component.result), 160);
      lines.push(theme.fg("dim", detail + (output ? ` · ${output}` : "")));
    } else if (level === 2) {
      lines.push(...expandedToolBody(component, bodyWidth, theme));
    }

    content.addChild(new Text(lines.join("\n"), 0, 0));
  }

  const box = new Box(padding, 1, (text) => theme.bg(groupBackground(components), text));
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
  const pendingExpansion = new WeakSet<ToolComponentLike>();
  let latestPadding: 0 | 1 = 1;
  let requestRender: (() => void) | undefined;

  const expandAfterRender = (tool: ToolComponentLike): void => {
    if (tool.expanded || pendingExpansion.has(tool)) return;
    pendingExpansion.add(tool);
    queueMicrotask(() => {
      pendingExpansion.delete(tool);
      if (getLevel() !== 2 || tool.expanded) return;
      tool.setExpanded(true);
      tool.ui?.requestRender();
    });
  };

  Container.prototype.render = function groupedContainerRender(width: number): string[] {
    const theme = getTheme();
    const children = this.children;
    const configuredPadding = outputPadding(children);
    if (configuredPadding !== undefined) latestPadding = configuredPadding;
    const hasTools = children.some(isToolComponent);
    if (!theme || !hasTools) return originalContainerRender.call(this, width);

    const lines: string[] = [];
    let pendingTools: ToolComponentLike[] = [];

    const flushTools = (): void => {
      if (pendingTools.length === 0) return;
      lines.push(
        ...renderToolGroup(
          pendingTools,
          width,
          getLevel(),
          completedCalls,
          theme,
          latestPadding,
        ),
      );
      pendingTools = [];
    };

    for (const child of children) {
      if (isToolComponent(child)) {
        const tool = child;
        pendingTools.push(tool);
        seenTools.add(tool);
        if (getLevel() === 2) expandAfterRender(tool);
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

  pi.registerMessageRenderer("workflow-result", (message, options, theme) => {
    const content = typeof message.content === "string" ? message.content : "";
    return {
      render(width: number): string[] {
        const display = workflowResultDisplay(content, theme as unknown as ThemeLike);
        const padding = options.outputPad === 0 ? 0 : 1;
        return plainBlock(
          display.title,
          wrapPlainBody(display.lines, width, padding),
          width,
          padding,
          theme as unknown as ThemeLike,
        );
      },
      invalidate() {},
    };
  });

  for (const customType of [
    "web-search-results",
    "web-search-content-ready",
    "web-search-error",
    "curator-config",
    "google-account",
  ]) {
    pi.registerMessageRenderer(customType, (message, options, theme) => ({
      render(width: number): string[] {
        return renderWebMessage(
          customType,
          message.content,
          width,
          options.outputPad,
          theme as unknown as ThemeLike,
        );
      },
      invalidate() {},
    }));
  }

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
