import re
from pathlib import Path
import httpx
from fastmcp import FastMCP

mcp = FastMCP("respond-help")


@mcp.tool()
def list_help_topics() -> str:
    """Return the full help topic index. Call this first to see all available help topics and their descriptions before deciding which article to fetch."""
    index_path = Path(__file__).parent / "index.md"
    if not index_path.exists():
        return "index.md not found. Run build_index.py to generate it."
    return index_path.read_text()


@mcp.tool()
def fetch_help(slug: str) -> str:
    """Fetch the full markdown content of a help article by its slug (e.g. 'quick-start/getting-started-with-respond-io'). Get the slug from list_help_topics first."""
    # Validate slug format
    if not re.match(r"^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$", slug):
        return "Invalid slug. Use format: category/article-name (e.g. quick-start/getting-started)"

    # Fetch from respond.io
    try:
        with httpx.Client(timeout=30.0) as client:
            response = client.get(f"https://respond.io/help/{slug}.md")
            response.raise_for_status()
            return response.text
    except httpx.HTTPStatusError as e:
        return f"Failed to fetch article: HTTP {e.response.status_code}"
    except httpx.RequestError as e:
        return f"Failed to fetch article: {str(e)}"


if __name__ == "__main__":
    mcp.run()
