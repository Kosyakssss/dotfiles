import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

const WIDGET_ID = "present-questions";

type Question = {
  question: string;
  context?: string;
};

function clean(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

function indentWrapped(lines: string[], first: string, rest: string): string[] {
  return lines.map((line, index) => `${index === 0 ? first : rest}${line}`);
}

function questionWidget(questions: Question[], theme: Theme) {
  return {
    render(width: number): string[] {
      const safeWidth = Math.max(1, width);
      const contentWidth = Math.max(1, safeWidth - 5);
      const lines: string[] = [];
      const count = `${questions.length} question${questions.length === 1 ? "" : "s"}`;

      lines.push(theme.fg("borderMuted", "─".repeat(safeWidth)));
      lines.push(
        theme.fg("accent", theme.bold(" Clarifications")) +
          theme.fg("dim", ` · ${count}`),
      );

      for (const [index, item] of questions.entries()) {
        const number = `${index + 1}.`;
        const prefix = ` ${number.padEnd(3)} `;
        const continuation = " ".repeat(prefix.length);
        const question = new Text(theme.fg("text", item.question), 0, 0).render(contentWidth);
        lines.push(...indentWrapped(question, theme.fg("accent", prefix), continuation));

        if (item.context) {
          const contextPrefix = "     ";
          const context = new Text(theme.fg("muted", item.context), 0, 0).render(
            Math.max(1, safeWidth - contextPrefix.length),
          );
          lines.push(...context.map((line) => `${contextPrefix}${line}`));
        }
      }

      lines.push(theme.fg("borderMuted", "─".repeat(safeWidth)));
      return lines;
    },
    invalidate(): void {},
  };
}

export default function presentQuestions(pi: ExtensionAPI) {
  let active = false;

  function clear(ctx: { ui: { setWidget(id: string, value: undefined): void } }): void {
    if (!active) return;
    ctx.ui.setWidget(WIDGET_ID, undefined);
    active = false;
  }

  pi.on("session_start", (_event, ctx) => clear(ctx));
  pi.on("session_shutdown", (_event, ctx) => clear(ctx));
  pi.on("session_tree", (_event, ctx) => clear(ctx));

  pi.on("input", (_event, ctx) => {
    clear(ctx);
    return { action: "continue" } as const;
  });

  pi.registerTool({
    name: "present_questions",
    label: "Present Questions",
    description:
      "Pin a short numbered set of clarification questions above the user's normal input field. This is a passive visual aid, not a blocking form: the user's next ordinary message is the answer and dismisses the list. Use only after presenting all relevant findings and reasoning in prose.",
    promptSnippet: "Pin numbered clarification questions above the user's input field",
    promptGuidelines: [
      "Use present_questions only when answers will materially change the next action; prefer 1-5 questions and never exceed 8.",
      "Before calling present_questions, write all findings, trade-offs, and recommendations the user should read. Do not include the clarification questions themselves in that prose.",
      "Put every clarification question only in present_questions. Add short per-question context only when the question cannot stand alone without scrolling; do not repeat the surrounding response.",
      "Call present_questions once as the final action of the response. Do not paraphrase, enumerate, or repeat its questions before or after the tool call.",
      "After present_questions returns, end the response and wait for the user's next ordinary message. Do not ask the user to use a special form; answers such as '1. ... 2. ...' are ordinary conversation.",
    ],
    parameters: Type.Object({
      questions: Type.Array(
        Type.Object({
          question: Type.String({
            minLength: 1,
            maxLength: 500,
            description: "One direct clarification question. Do not include its number.",
          }),
          context: Type.Optional(
            Type.String({
              minLength: 1,
              maxLength: 500,
              description: "Optional short context needed to answer this item without scrolling.",
            }),
          ),
        }),
        { minItems: 1, maxItems: 8 },
      ),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      if (signal?.aborted) throw new Error("Cancelled");

      const questions = params.questions.map((item) => ({
        question: clean(item.question),
        context: item.context ? clean(item.context) : undefined,
      }));

      const interactive = ctx.mode === "tui";
      if (interactive) {
        ctx.ui.setWidget(
          WIDGET_ID,
          (_tui, theme) => questionWidget(questions, theme),
          { placement: "aboveEditor" },
        );
        active = true;
      }

      return {
        content: [
          {
            type: "text",
            text: interactive
              ? `Pinned ${questions.length} clarification question${questions.length === 1 ? "" : "s"}. End the response now and wait for the user's next message.`
              : questions.map((item, index) => `${index + 1}. ${item.question}`).join("\n"),
          },
        ],
        details: { questions },
        terminate: true,
      };
    },
    renderCall(_args, theme) {
      return new Text(theme.fg("toolTitle", "Pin clarification questions"), 0, 0);
    },
    renderResult(result, _options, theme) {
      const details = result.details as { questions?: Question[] } | undefined;
      const count = details?.questions?.length ?? 0;
      return new Text(
        count > 0
          ? theme.fg("dim", `Pinned ${count} clarification question${count === 1 ? "" : "s"}`)
          : theme.fg("dim", "Clarification questions prepared"),
        0,
        0,
      );
    },
  });
}
