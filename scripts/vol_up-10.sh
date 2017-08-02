#!/bin/bash

amixer --quiet set Master 10%+
amixer sget Master | grep %
