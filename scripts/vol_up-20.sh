#!/bin/bash

amixer --quiet set Master 20%+
amixer sget Master | grep %
