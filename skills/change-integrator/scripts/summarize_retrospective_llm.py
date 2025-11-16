#!/usr/bin/env python3
"""
LLM-based retrospective summarizer for the change-integrator skill.

This script uses an LLM to generate a structured and insightful summary
from 'went well' and 'lesson learned' inputs for the RETROSPECTIVE.md file.
"""

import sys
import subprocess
import argparse


def call_llm_for_summary(went_well: str, lesson_learned: str) -> str:
    """
    Calls the LLM to generate a retrospective summary.

    Args:
        went_well: The 'went well' input from the user.
        lesson_learned: The 'lesson learned' input from the user.

    Returns:
        The LLM-generated summary as a string.
        Returns an empty string if the LLM call fails.
    """
    prompt = f"""You are an assistant that helps write project retrospectives.
Based on the following points, please write a concise, structured summary for a retrospective document.
The summary should be in markdown format and focus on extracting key insights and learnings.

**What Went Well:**
{went_well}

**Lesson Learned:**
{lesson_learned}

Please provide a well-structured summary that:
1. Highlights the key successes and positive outcomes
2. Emphasizes the main lesson learned and its implications
3. Is suitable for a professional engineering team's retrospective document
4. Uses clear, concise markdown formatting

Return ONLY the markdown summary without any additional explanation or preamble.
"""

    try:
        # Using gemini-2.5-flash for efficient text generation
        result = subprocess.run(
            ['gemini', '--model', 'gemini-2.5-flash'],
            input=prompt,
            capture_output=True,
            text=True,
            timeout=45,
            check=True  # This will raise CalledProcessError for non-zero exit codes
        )
        return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError, subprocess.CalledProcessError) as e:
        print(f"Warning: LLM call failed: {e}", file=sys.stderr)
        return ""


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='LLM-based retrospective summarizer.'
    )
    parser.add_argument(
        '--went-well',
        required=True,
        help='What went well with this change.'
    )
    parser.add_argument(
        '--lesson-learned',
        required=True,
        help='What was learned from this change.'
    )
    args = parser.parse_args()

    summary = call_llm_for_summary(args.went_well, args.lesson_learned)

    if summary:
        print(summary)
        sys.exit(0)
    else:
        # Exit with a non-zero status code to indicate failure
        sys.exit(1)


if __name__ == '__main__':
    main()
