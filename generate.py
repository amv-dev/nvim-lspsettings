#!/usr/bin/env python3

import requests
import logging
import json

from typing import Any, Callable, Dict

LSP_LIST_URL = "https://gist.githubusercontent.com/tamago324/6c065d5914388ddddd9518bd8fb75c8c/raw/lsp-packages.json"
logger = logging.getLogger(__name__)


def download(url: str) -> Any:
    return requests.get(url).json()


def load_schemas_list() -> Dict[str, str]:
    return download(LSP_LIST_URL)


def load_lsp_schema(url: str) -> Any:
    return download(url)


def direct_properties_parser(full_schema: Any) -> Any:
    return full_schema["properties"]


def project_properties_parser(full_schema: Any) -> Any:
    defs = full_schema["definitions"]
    project = defs["Project"]

    return project["properties"]


def default_parser(full_schema: Any) -> Any:
    ctrb = full_schema["contributes"]
    confs = ctrb["configuration"]

    props = {}

    if type(confs) == dict:
        confs = [confs]

    for conf in confs:
        if "properties" not in conf:
            continue

        props |= conf["properties"]

    return props


def get_parser(_server_name, full_schema) -> Callable:
    if "contributes" in full_schema:
        return default_parser

    if "definitions" in full_schema:
        definitions = full_schema["definitions"]

        if "Project" in definitions:
            return project_properties_parser

    if "properties" in full_schema:
        return direct_properties_parser

    return default_parser


def process_schema(server_name: str, full_schema: Any) -> Any:
    parser = get_parser(server_name, full_schema)
    props = parser(full_schema)

    return {
        "$schema": "http://json-schema.org/draft-04/schema#",
        "description": f"LSP settings for `{server_name}`",
        "properties": props,
    }


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    urls = load_schemas_list()

    for server_name in urls:
        logger.info(f"Processing `{server_name}` schema...")
        full_schema = load_lsp_schema(urls[server_name])

        logger.info(f"Parsing schema for `{server_name}`...")
        schema = process_schema(server_name, full_schema)

        logger.info(f"Saving schema for `{server_name}`...")
        with open(f"{server_name}.json", "w") as f:
            json.dump(schema, f, indent=4)
