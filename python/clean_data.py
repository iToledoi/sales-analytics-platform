# python/clean_data.py

"""Clean raw CSV files and write normalized copies into data/cleaned."""

from __future__ import annotations

from pathlib import Path

import pandas as pd
import logging

from config import CLEAN_DATA_DIR, RAW_DATA_DIR, LOG_FILE, REPORT_FILE
from utils import clean_currency, clean_dates, clean_whitespace, read_csv_with_fallback, replace_nulls
from validators import validate_dataframe


def _clean_column(name: str, series: pd.Series) -> tuple[pd.Series, dict[str, int]]:
	stats = {"currency_symbols_removed": 0, "dates_converted": 0}
	cleaned = replace_nulls(series)
	cleaned = clean_whitespace(cleaned)

	if any(token in name.lower() for token in ("date", "timestamp")):
		parsed = clean_dates(cleaned)
		stats["dates_converted"] = int(pd.Series(parsed).notna().sum())
		return parsed, stats

	if any(token in name.lower() for token in ("price", "value", "amount")):
		string_values = cleaned.astype("string")
		currency_symbols_removed = int(string_values.str.count(r"[€$£¥]").fillna(0).sum())
		currency_symbols_removed += int(string_values.str.count(r"R\$").fillna(0).sum())
		stats["currency_symbols_removed"] = currency_symbols_removed
		return clean_currency(cleaned), stats

	return cleaned, stats


def _output_name(raw_file: Path) -> str:
	name = raw_file.name
	if name.startswith("olist_") and name.endswith("_dataset.csv"):
		return name.replace("olist_", "").replace("_dataset", "")
	if name.endswith("_dataset.csv"):
		return name.replace("_dataset", "")
	return name


def clean_file(raw_file: Path, cleaned_dir: Path) -> dict[str, object]:
	frame = read_csv_with_fallback(raw_file)
	raw_rows = len(frame)
	column_stats = {"currency_symbols_removed": 0, "dates_converted": 0}

	for column in frame.columns:
		cleaned_series, stats = _clean_column(column, frame[column])
		frame[column] = cleaned_series
		column_stats["currency_symbols_removed"] += stats["currency_symbols_removed"]
		column_stats["dates_converted"] += stats["dates_converted"]

	before_dedup = len(frame)
	frame = frame.drop_duplicates().reset_index(drop=True)
	removed_by_dedup = before_dedup - len(frame)

	validation = validate_dataframe(frame, raw_file.name)

	output_file = cleaned_dir / _output_name(raw_file)
	frame.to_csv(output_file, index=False)

	return {
		"raw_name": raw_file.name,
		"display_name": raw_file.stem.replace("olist_", "").replace("_dataset", "").replace("_", " ").title(),
		"output_name": output_file.name,
		"raw_rows": raw_rows,
		"clean_rows": len(frame),
		"rows_removed": raw_rows - len(frame),
		"duplicates_removed": removed_by_dedup,
		"currency_symbols_removed": column_stats["currency_symbols_removed"],
		"dates_converted": column_stats["dates_converted"],
		"validation": validation,
	}


def _pretty_number(value: int) -> str:
	return f"{value:,}"


def _center_title(text: str, width: int) -> list[str]:
	return ["=" * width, text.center(width), "=" * width, ""]


def _format_missing_values(missing_by_column: dict[str, int]) -> list[str]:
	if not missing_by_column:
		return ["None"]

	formatted: list[str] = []
	for column, count in sorted(missing_by_column.items(), key=lambda item: (-item[1], item[0])):
		formatted.append(f"{column.ljust(32, '.')} {_pretty_number(count)}")
	return formatted


def _format_validation_warnings(issues: list[str]) -> list[str]:
	if not issues:
		return ["None"]

	return [f"- {issue}" for issue in issues]





def main() -> None:
	raw_dir = Path(RAW_DATA_DIR)
	cleaned_dir = Path(CLEAN_DATA_DIR)
	report_file = Path(REPORT_FILE)
	cleaned_dir.mkdir(parents=True, exist_ok=True)
	report_file.parent.mkdir(parents=True, exist_ok=True)

	raw_files = sorted(raw_dir.glob("*.csv"))
	if not raw_files:
		logging.error(f"No CSV files found in {raw_dir}")
		return

	logging.info(f"Cleaning {len(raw_files)} files from {raw_dir} into {cleaned_dir}")

	processed_files: list[dict[str, object]] = []
	total_raw_rows = 0
	total_rows = 0
	total_currency_symbols_removed = 0
	total_dates_converted = 0
	total_duplicates_removed = 0
	total_validation_warnings = 0
	for raw_file in raw_files:
		file_report = clean_file(raw_file, cleaned_dir)
		processed_files.append(file_report)
		total_raw_rows += int(file_report["raw_rows"])
		total_rows += int(file_report["clean_rows"])
		total_duplicates_removed += int(file_report["duplicates_removed"])
		total_currency_symbols_removed += int(file_report["currency_symbols_removed"])
		total_dates_converted += int(file_report["dates_converted"])
		total_validation_warnings += len(file_report["validation"]["issues"])
		logging.info(f"- {raw_file.name} -> {file_report['output_name']} ({file_report['clean_rows']} rows)")
		for issue in file_report["validation"]["issues"]:
			logging.warning(f"  warning: {issue}")
		logging.info(f"Processed {raw_file.name}: {file_report['clean_rows']} rows, {len(file_report['validation']['issues'])} issues")

	summary = {
		"files_processed": len(raw_files),
		"rows_processed": total_rows,
		"rows_removed": total_raw_rows - total_rows,
		"currency_symbols_removed": total_currency_symbols_removed,
		"dates_converted": total_dates_converted,
		"duplicates_removed": total_duplicates_removed,
		"validation_warnings": total_validation_warnings,
	}

	report_text = _build_report(processed_files, summary, "data/cleaned/")
	report_file.write_text(report_text, encoding="utf-8")

	logging.info(f"Wrote validation report to {report_file}")
	logging.info(f"Finished cleaning {len(raw_files)} files and {total_rows} total rows.")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)

if __name__ == "__main__":
	main()