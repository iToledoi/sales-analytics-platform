# python/validators.py

"""Data validation for cleaned datasets."""

from __future__ import annotations

import pandas as pd

PRIMARY_KEY_COLUMNS = {
	"olist_customers_dataset.csv": ["customer_id"],
	"olist_geolocation_dataset.csv": [],
	"olist_order_items_dataset.csv": [],
	"olist_order_payments_dataset.csv": [],
	"olist_order_reviews_dataset.csv": ["review_id"],
	"olist_orders_dataset.csv": ["order_id"],
	"olist_products_dataset.csv": ["product_id"],
	"olist_sellers_dataset.csv": ["seller_id"],
	"product_category_name_translation.csv": ["product_category_name"],
}


def _format_issue(message: str) -> str:
	return f"- {message}"


def validate_dataframe(frame: pd.DataFrame, dataset_name: str) -> dict[str, object]:
	issues: list[str] = []

	missing_by_column = {
		column: int(frame[column].isna().sum())
		for column in frame.columns
		if int(frame[column].isna().sum()) > 0
	}
	missing_values = int(sum(missing_by_column.values()))
	if missing_values:
		issues.append(f"{missing_values} missing values remain")

	duplicate_count = 0
	for column in PRIMARY_KEY_COLUMNS.get(dataset_name, []):
		if column not in frame.columns:
			continue

		column_duplicates = int(frame[column].duplicated().sum())
		duplicate_count += column_duplicates
		if column_duplicates:
			issues.append(f"{column_duplicates} duplicate values found in {column}")

	price_columns = [column for column in frame.columns if any(token in column.lower() for token in ("price", "value", "amount"))]
	negative_count = 0
	for column in price_columns:
		numeric_values = pd.to_numeric(frame[column], errors="coerce")
		column_negative_count = int((numeric_values < 0).sum())
		negative_count += column_negative_count
		if column_negative_count:
			issues.append(f"{column_negative_count} negative values found in {column}")

	invalid_review_scores = 0
	if "review_score" in frame.columns:
		scores = pd.to_numeric(frame["review_score"], errors="coerce")
		invalid_review_scores = int(((scores < 1) | (scores > 5) | scores.isna()).sum())
		if invalid_review_scores:
			issues.append(f"{invalid_review_scores} invalid review_score values")

	date_columns = [column for column in frame.columns if any(token in column.lower() for token in ("date", "timestamp"))]
	invalid_dates = 0
	for column in date_columns:
		parsed_dates = pd.to_datetime(frame[column], errors="coerce")
		column_invalid_dates = int(frame[column].notna().sum() - parsed_dates.notna().sum())
		invalid_dates += column_invalid_dates
		if column_invalid_dates:
			issues.append(f"{column_invalid_dates} invalid dates found in {column}")

	return {
		"dataset_name": dataset_name,
		"rows": int(len(frame)),
		"duplicates": int(duplicate_count),
		"missing_values": int(missing_values),
		"missing_by_column": missing_by_column,
		"negative_values": int(negative_count),
		"invalid_review_scores": int(invalid_review_scores),
		"invalid_dates": int(invalid_dates),
		"issues": issues,
	}