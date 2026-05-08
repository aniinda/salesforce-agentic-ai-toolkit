"""RAG pipeline for Salesforce Knowledge using FAISS and Claude."""

from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Iterable

import anthropic
from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from simple_salesforce import Salesforce


@dataclass
class KnowledgeArticle:
    article_id: str
    title: str
    body: str


def salesforce_client() -> Salesforce:
    return Salesforce(
        username=os.environ["SALESFORCE_USERNAME"],
        password=os.environ["SALESFORCE_PASSWORD"],
        security_token=os.environ["SALESFORCE_SECURITY_TOKEN"],
        domain=os.environ.get("SALESFORCE_DOMAIN", "login"),
    )


def fetch_knowledge_articles(limit: int = 100) -> list[KnowledgeArticle]:
    sf = salesforce_client()
    query = (
        "SELECT Id, Title, Summary "
        "FROM Knowledge__kav "
        "WHERE PublishStatus = 'Online' "
        f"LIMIT {limit}"
    )
    rows = sf.query(query).get("records", [])
    return [
        KnowledgeArticle(
            article_id=row["Id"],
            title=row.get("Title") or "Untitled",
            body=row.get("Summary") or "",
        )
        for row in rows
    ]


def build_vector_store(articles: Iterable[KnowledgeArticle]) -> FAISS:
    splitter = RecursiveCharacterTextSplitter(chunk_size=900, chunk_overlap=120)
    texts: list[str] = []
    metadatas: list[dict[str, str]] = []

    for article in articles:
        for chunk in splitter.split_text(article.body):
            texts.append(chunk)
            metadatas.append({"article_id": article.article_id, "title": article.title})

    if not texts:
        raise ValueError("No Knowledge article text available for indexing.")

    return FAISS.from_texts(texts, OpenAIEmbeddings(), metadatas=metadatas)


def answer_question(question: str, vector_store: FAISS) -> str:
    docs = vector_store.similarity_search(question, k=4)
    context = "\n\n".join(
        f"Source: {doc.metadata.get('title')} ({doc.metadata.get('article_id')})\n{doc.page_content}"
        for doc in docs
    )

    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    message = client.messages.create(
        model="claude-3-5-sonnet-latest",
        max_tokens=900,
        system="Answer only from the provided Salesforce Knowledge context. Cite article titles.",
        messages=[{"role": "user", "content": f"Question: {question}\n\nContext:\n{context}"}],
    )
    return "\n".join(block.text for block in message.content if block.type == "text")


if __name__ == "__main__":
    user_question = os.environ.get("RAG_QUESTION", "How should support triage a renewal-risk case?")
    store = build_vector_store(fetch_knowledge_articles())
    print(answer_question(user_question, store))
