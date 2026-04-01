# MCP Guide

## Purpose
This document explains how model context protocol integrations fit into the repository workflow.

## General guidance
- Add MCP integrations only when they solve a real workflow problem
- Keep the core workflow functional even if a connector is missing
- Document any new integration in `integration-contracts.md`
- Record operational notes in `runbook.md`

## Useful categories
- Documentation MCPs
- Issue and repository MCPs
- Planning or reasoning MCPs
- Tool search or lazy loading layers

## Rule
If an MCP changes the workflow, the repository memory must reflect that change.
