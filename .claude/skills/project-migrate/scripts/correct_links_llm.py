#!/usr/bin/env python3
"""
LLM-based link correction for project-migrate skill

This script uses an LLM to intelligently identify and correct broken or outdated
links within markdown content during file migration.
"""

import sys
import os
import re
import argparse
import json
import subprocess
from pathlib import Path
from typing import List, Dict, Tuple, Optional


def extract_markdown_links(content: str) -> List[Dict]:
    """
    Extract all markdown links from content and return structured information.

    Args:
        content: Markdown content to analyze

    Returns:
        List of dictionaries with link information
    """
    links = []

    # Pattern to match markdown links: [text](path) and ![alt](path)
    pattern = r'!\[([^\]]*)\]\(([^)]+)\)|\[([^\]]*)\]\(([^)]+)\)'

    for match in re.finditer(pattern, content):
        alt_text, img_src, link_text, link_href = match.groups()

        if img_src:
            # Image link
            links.append({
                'type': 'image',
                'alt': alt_text,
                'path': img_src,
                'full_match': match.group(0)
            })
        elif link_href:
            # Regular link
            links.append({
                'type': 'link',
                'text': link_text,
                'path': link_href,
                'full_match': match.group(0)
            })

    return links


def should_skip_link(link_path: str) -> bool:
    """
    Determine if a link should be skipped (external URLs, anchors, etc.).

    Args:
        link_path: The path part of the link

    Returns:
        True if the link should be skipped
    """
    # Skip absolute URLs
    if link_path.startswith(('http://', 'https://', 'mailto:', 'ftp://', 'tel:')):
        return True

    # Skip anchor links
    if link_path.startswith('#'):
        return True

    # Skip email links without mailto prefix
    if '@' in link_path and not link_path.startswith(('http://', 'https://')):
        return True

    return False


def get_file_context(file_path: str) -> Dict:
    """
    Get context about the file being processed.

    Args:
        file_path: Path to the file

    Returns:
        Dictionary with file context information
    """
    path = Path(file_path)

    try:
        relative_to_root = str(path.relative_to(Path.cwd()))
    except ValueError:
        # Handle case where file is not subdirectory of current working directory
        relative_to_root = str(path)

    context = {
        'file_path': str(path.absolute()),
        'filename': path.name,
        'directory': str(path.parent.absolute()),
        'relative_to_root': relative_to_root,
    }

    return context


def call_llm_for_link_correction(content: str, context: Dict) -> str:
    """
    Call LLM to perform intelligent link correction.

    Args:
        content: Original markdown content
        context: File context information

    Returns:
        Corrected markdown content
    """
    try:
        # Prepare the prompt for the LLM
        prompt = f"""You are a markdown link correction assistant. Your task is to identify and correct broken or outdated relative links in the following markdown content.

Context:
- File: {context['relative_to_root']}
- Directory: {context['directory']}

Instructions:
1. Analyze all relative links in the content
2. For each link, determine if it points to an existing file
3. If a link appears broken or outdated, suggest a corrected path
4. Common migrations to consider:
   - Files moved from root to docs/ directory
   - Files moved from docs/ to docs/specs/ or docs/changes/
   - Changes in file extensions or naming conventions
5. Preserve all external URLs, anchors, and email links unchanged
6. Only modify links that clearly need correction

Return ONLY the corrected markdown content without any additional explanation.

Content to analyze:
{content}"""

        # Call Gemini CLI if available, otherwise fallback to a simple pass-through
        try:
            result = subprocess.run(
                ['gemini', '--model', 'gemini-2.5-flash'],
                input=prompt,
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip()
        except (subprocess.TimeoutExpired, FileNotFoundError):
            # Gemini not available or timed out - fallback to basic processing
            pass

    except Exception as e:
        print(f"Warning: LLM call failed: {e}", file=sys.stderr)

    # Fallback: return original content unchanged
    return content


def validate_corrected_links(original: str, corrected: str) -> Dict[str, int]:
    """
    Compare original and corrected content to count changes.

    Args:
        original: Original markdown content
        corrected: Corrected markdown content

    Returns:
        Dictionary with change statistics
    """
    original_links = extract_markdown_links(original)
    corrected_links = extract_markdown_links(corrected)

    original_paths = {link['path'] for link in original_links if not should_skip_link(link['path'])}
    corrected_paths = {link['path'] for link in corrected_links if not should_skip_link(link['path'])}

    changes = {
        'total_links': len(original_links),
        'skipped_links': len([link for link in original_links if should_skip_link(link['path'])]),
        'corrected_links': len(original_paths - corrected_paths),
        'new_links': len(corrected_paths - original_paths)
    }

    return changes


def correct_links_in_content(content: str, file_path: str) -> Tuple[str, Dict]:
    """
    Correct links in markdown content using LLM.

    Args:
        content: Markdown content to process
        file_path: Path to the file being processed

    Returns:
        Tuple of (corrected_content, statistics)
    """
    # Extract links for analysis
    links = extract_markdown_links(content)

    # Filter for links that need processing
    processable_links = [link for link in links if not should_skip_link(link['path'])]

    if not processable_links:
        # No links to process
        return content, {
            'total_links': len(links),
            'processable_links': 0,
            'corrected_links': 0,
            'llm_called': False
        }

    # Get file context
    context = get_file_context(file_path)

    # Call LLM for correction
    corrected_content = call_llm_for_link_correction(content, context)

    # Validate changes
    changes = validate_corrected_links(content, corrected_content)
    changes.update({
        'processable_links': len(processable_links),
        'llm_called': True
    })

    return corrected_content, changes


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='LLM-based markdown link correction',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Correct links in a file
  cat README.md | correct_links_llm.py --file README.md

  # Process multiple files
  find docs -name "*.md" -exec correct_links_llm.py --file {} \\;

  # Show statistics only
  cat file.md | correct_links_llm.py --file file.md --stats-only
        """
    )

    parser.add_argument(
        '--file',
        required=True,
        help='Path to the file being processed (required for context)'
    )

    parser.add_argument(
        '--stats-only',
        action='store_true',
        help='Only show statistics, don\'t output corrected content'
    )

    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Analyze without making changes'
    )

    args = parser.parse_args()

    try:
        # Read content from stdin
        content = sys.stdin.read()

        if not content.strip():
            print("Error: No content provided on stdin", file=sys.stderr)
            sys.exit(1)

        # Correct links
        corrected_content, stats = correct_links_in_content(content, args.file)

        # Output statistics
        if stats['llm_called']:
            print(f"Link correction statistics for {args.file}:", file=sys.stderr)
            print(f"  Total links: {stats['total_links']}", file=sys.stderr)
            print(f"  Processable links: {stats['processable_links']}", file=sys.stderr)
            print(f"  Corrected links: {stats['corrected_links']}", file=sys.stderr)
            print(f"  Skipped links: {stats['skipped_links']}", file=sys.stderr)
        else:
            print(f"No links to process in {args.file}", file=sys.stderr)

        # Output corrected content (unless stats-only)
        if not args.stats_only:
            print(corrected_content)

    except KeyboardInterrupt:
        print("\nInterrupted by user", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()