"""LangChain Salesforce agent example.

Environment variables:
    SALESFORCE_USERNAME
    SALESFORCE_PASSWORD
    SALESFORCE_SECURITY_TOKEN
    SALESFORCE_DOMAIN
    OPENAI_API_KEY
"""

from __future__ import annotations

import os
from typing import Any

from langchain.agents import AgentExecutor, create_react_agent
from langchain.prompts import PromptTemplate
from langchain.tools import Tool
from langchain_openai import ChatOpenAI
from simple_salesforce import Salesforce


def salesforce_client() -> Salesforce:
    return Salesforce(
        username=os.environ["SALESFORCE_USERNAME"],
        password=os.environ["SALESFORCE_PASSWORD"],
        security_token=os.environ["SALESFORCE_SECURITY_TOKEN"],
        domain=os.environ.get("SALESFORCE_DOMAIN", "login"),
    )


def run_soql(query: str) -> str:
    sf = salesforce_client()
    result: dict[str, Any] = sf.query(query)
    records = result.get("records", [])
    cleaned = [{k: v for k, v in record.items() if k != "attributes"} for record in records]
    return str(cleaned[:20])


def build_agent() -> AgentExecutor:
    tools = [
        Tool(
            name="salesforce_soql",
            func=run_soql,
            description="Run safe read-only SOQL queries against Salesforce. Input must be a SELECT query.",
        )
    ]
    llm = ChatOpenAI(model="gpt-4.1-mini", temperature=0)
    prompt = PromptTemplate.from_template(
        """You answer CRM questions by creating read-only SOQL queries.
Use only SELECT statements. Never modify Salesforce data.

Tools:
{tools}

Tool names: {tool_names}

Question: {input}
Thought: {agent_scratchpad}"""
    )
    agent = create_react_agent(llm, tools, prompt)
    return AgentExecutor(agent=agent, tools=tools, verbose=True, handle_parsing_errors=True)


if __name__ == "__main__":
    question = os.environ.get("CRM_QUESTION", "Show five open opportunities closing this quarter.")
    executor = build_agent()
    print(executor.invoke({"input": question})["output"])
