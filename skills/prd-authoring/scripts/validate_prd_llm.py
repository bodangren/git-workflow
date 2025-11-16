#!/usr/bin/env python3
"""
LLM-based PRD quality validator for the prd-authoring skill.

This script uses an LLM to analyze PRD files for quality issues such as
untestable requirements and unclear success criteria.
"""

import sys
import subprocess
import argparse


def analyze_prd_quality(prd_content: str) -> str:
    """
    Calls the LLM to perform quality analysis on a PRD.

    Args:
        prd_content: The full content of the PRD file.

    Returns:
        The LLM's analysis as a string.
        Returns an empty string if the LLM call fails.
    """
    prompt = f"""You are a technical product manager reviewing a Product Requirements Document (PRD) for quality issues.

Please analyze the following PRD and identify:

1. **Untestable Requirements**: Requirements that are difficult or impossible to test because they lack:
   - Clear, measurable acceptance criteria
   - Specific, quantifiable metrics
   - Objective verification methods
   - Clear pass/fail conditions

2. **Unclear Success Criteria**: Success criteria that are ambiguous or poorly defined because they:
   - Use vague or subjective language
   - Lack specific numeric targets or thresholds
   - Are not measurable or verifiable
   - Don't specify timeframes or measurement methods

For each issue found, provide:
- The section/requirement where the issue appears (with line reference if possible)
- A brief explanation of why it's problematic
- A specific suggestion for improvement

If the PRD is well-written with clear, testable requirements and measurable success criteria, respond with exactly: "No quality issues found. The PRD has clear, testable requirements and well-defined success criteria."

Format your response in markdown with clear sections for Untestable Requirements and Unclear Success Criteria.

---

PRD CONTENT:

{prd_content}

---

ANALYSIS:
"""

    try:
        # Using gemini-2.5-flash for text analysis
        result = subprocess.run(
            ['gemini', '--model', 'gemini-2.5-flash'],
            input=prompt,
            capture_output=True,
            text=True,
            timeout=60,
            check=True  # This will raise CalledProcessError for non-zero exit codes
        )
        return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError, subprocess.CalledProcessError) as e:
        print(f"Warning: LLM quality analysis failed: {e}", file=sys.stderr)
        return ""


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='LLM-based PRD quality validator.'
    )
    parser.add_argument(
        '--prd-file',
        required=True,
        help='Path to the PRD file to analyze.'
    )
    args = parser.parse_args()

    try:
        # Read PRD content from file
        with open(args.prd_file, 'r', encoding='utf-8') as f:
            prd_content = f.read()

        if not prd_content.strip():
            print("Error: PRD file is empty", file=sys.stderr)
            sys.exit(1)

        # Perform LLM analysis
        analysis = analyze_prd_quality(prd_content)

        if analysis:
            print(analysis)
            sys.exit(0)
        else:
            # Exit with non-zero status code to indicate failure
            sys.exit(1)

    except FileNotFoundError:
        print(f"Error: PRD file not found: {args.prd_file}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
