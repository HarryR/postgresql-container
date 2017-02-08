#!/usr/bin/env bash
ufw allow 22/tcp
ufw allow 5432/tcp
ufw --force enable