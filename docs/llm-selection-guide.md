# LLM Selection Guide

## Decision Framework

Use the model that satisfies the workflow with the least operational complexity. Native Salesforce AI should be the first option when the data, action, and governance requirements are inside Salesforce. External LLMs are appropriate when the task requires advanced language generation, broader context windows, custom retrieval, or cross-platform orchestration.

| Use Case | Claude | OpenAI | Einstein Native |
| --- | --- | --- | --- |
| Long case summarization | Strong fit for long context and careful prose | Strong fit for concise summaries and tool workflows | Good when using native Service Cloud features |
| Lead scoring explanation | Good for readable rationale | Good for structured JSON and function-style outputs | Best for native predictive scoring |
| Next-best-action generation | Strong for policy-heavy recommendations | Strong for multi-step tool plans | Best when NBA strategy is already configured |
| Knowledge-grounded answers | Good with RAG and citations | Good with RAG and tool orchestration | Good for Salesforce Knowledge-native experiences |
| Forecast or churn prediction | Use only for explanation | Use only for explanation | Best fit for Discovery or Prediction Builder |

## Claude

Claude is often a strong fit for long-form synthesis, policy-sensitive reasoning, and tasks requiring careful instruction following. Use it when prompts include lengthy case histories, knowledge excerpts, or governance rubrics.

## OpenAI

OpenAI is often a strong fit for structured outputs, tool invocation, multimodal extensions, and workflows that need robust application integration. Use it when downstream systems need predictable JSON responses.

## Einstein Native

Einstein is preferred when the prediction or recommendation is natively supported, requires CRM governance, and must be surfaced directly in Salesforce with minimal integration overhead.

## Selection Principles

- Keep predictive scoring in Einstein when possible.
- Use external LLMs to explain, summarize, draft, and orchestrate.
- Use RAG when answers must be grounded in internal content.
- Require human approval for generated content that affects customers, pricing, legal obligations, or revenue recognition.
