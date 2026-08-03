# python/utils.py

"""Shared cleaning functions for the CSV pipeline."""

from __future__ import annotations

import re
from pathlib import Path

import pandas as pd


NULL_LIKE_VALUES = {"", " ", "na", "n/a", "null", "none", "nan", "?", "-"}
CURRENCY_PATTERN = re.compile(r"[€$£R$¥]")


def clean_whitespace(series: pd.Series) -> pd.Series:
    if not pd.api.types.is_object_dtype(series) and not pd.api.types.is_string_dtype(series):
        return series

    cleaned = series.astype("string").str.strip()
    cleaned = cleaned.str.replace(r"\s+", " ", regex=True)
    return cleaned


def replace_nulls(series: pd.Series) -> pd.Series:
    if not pd.api.types.is_object_dtype(series) and not pd.api.types.is_string_dtype(series):
        return series

    cleaned = series.astype("string")
    cleaned = cleaned.replace({value: pd.NA for value in NULL_LIKE_VALUES}, regex=False)
    cleaned = cleaned.replace(r"^\s*$", pd.NA, regex=True)
    return cleaned


def clean_currency(series: pd.Series) -> pd.Series:
    if not pd.api.types.is_object_dtype(series) and not pd.api.types.is_string_dtype(series):
        return series

    values = series.astype("string")
    if not values.dropna().str.contains(CURRENCY_PATTERN).any():
        return series

    cleaned = values.str.replace(r"[€$£R$¥\s]", "", regex=True)
    cleaned = cleaned.str.replace(",", ".", regex=False)
    return pd.to_numeric(cleaned, errors="ignore")


def clean_dates(series: pd.Series) -> pd.Series:
    if not pd.api.types.is_object_dtype(series) and not pd.api.types.is_string_dtype(series):
        return series

    parsed = pd.to_datetime(series, errors="coerce")
    if parsed.notna().sum() == 0:
        return series
    return parsed


def read_csv_with_fallback(file_path: str | Path) -> pd.DataFrame:
    for encoding in ("utf-8-sig", "utf-8", "latin1"):
        try:
            return pd.read_csv(file_path, encoding=encoding)
        except UnicodeDecodeError:
            continue

    return pd.read_csv(file_path, encoding="latin1")