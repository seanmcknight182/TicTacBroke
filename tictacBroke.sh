#!/usr/bin/env bash
# Tic-Tac-Toe with minimax + alpha-beta pruning (Bash)
# Author: Regis Billings and M365 Copilot (colorless v4)
# - No ANSI colors; plain ASCII so it renders consistently everywhere.
# - Portable to Bash 3.x+; avoids echo -e and ${var^^}.

# ========== Global State ==========
# Board is 9 cells indexed 0..8, each is " " or "X" or "O"
board=(" " " " " " " " " " " " " " " " " ")
HUMAN="X"
AI="O"
TURN="HUMAN"  # or "AI"

#License and file integrity check

FILE1="README.txt"
FILE2="license"

# Verify both files exist
if [[ -f "$FILE1" && -f "$FILE2" ]]; then
    echo "All required files are present. Proceeding..."
else
    echo "This was downloaded illegally!"
    exit 1
fi

# ========== Utilities ==========
print_header() {
  printf "Tic-Tac-Toe — You vs AI\n"
  printf "Choose 1–9 to place your mark. (Numbers show in empty cells)\n"
}

cell_text() {
  # prints the rendered cell to stdout (no trailing newline)
  local i="$1" v="${board[$1]}"
  if [ "$v" = " " ]; then
    printf "%s" "$((i+1))"
  else
    printf "%s" "$v"
  fi
}

print_board() {
  command -v clear >/dev/null 2>&1 && clear
  print_header
  printf "\n"
  local r i
  for r in 0 1 2; do
    i=$((r*3))
    printf "  "
    cell_text $i;        printf " | "
    cell_text $((i));  printf " | "
    cell_text $((i+1));  printf "\n"
    if [ $r -lt 2 ]; then
      printf " ---+---+---\n"
    fi
  done
  printf "\n"
}

# Returns one of: X, O, D (draw), N (no result yet)
check_winner() {
  local lines=(
    "0 1 2" "3 4 5"
    "0 3 6" "1 4 7" "2 5 8"
    "0 4 8" "2 4 6"
  )
  local a b c L
  for L in "${lines[@]}"; do
    set -- $L; a=$1; b=$2; c=$3
    if [ "${board[$a]}" != " " ] && [ "${board[$a]}" = "${board[$b]}" ] && [ "${board[$b]}" = "${board[$c]}" ]; then
      printf "%s\n" "${board[$a]}"; return
    fi
  done
  local i
  for i in 0 1 2 3 4 5 6 7 8; do
    if [ "${board[$i]}" = " " ]; then printf "%s\n" N; return; fi
  done
  printf "%s\n" D
}

# ========== Minimax with Alpha-Beta ==========
# Echoes: "<score> <bestMoveIndex>"
# score > 0 favors AI, score < 0 favors HUMAN.
# Depth is used to prefer faster wins (10 - depth) and slower losses (depth - 10).
minimax() {
  local player="$1" depth="$2" alpha="$3" beta="$4"
  local result
  result=$(check_winner)
  if [ "$result" = "$AI" ]; then
    printf "%s %s\n" $((10 - depth)) -1; return
  elif [ "$result" = "$HUMAN" ]; then
    printf "%s %s\n" $((depth - 10)) -1; return
  elif [ "$result" = "D" ]; then
    printf "%s %s\n" 0 -1; return
  fi

  local bestScore bestMove score move nextPlayer i
  if [ "$player" = "$AI" ]; then
    bestScore=-1000; bestMove=-1; nextPlayer="$HUMAN"
    for i in 0 1 2 3 4 5 6 7 8; do
      if [ "${board[$i]}" = " " ]; then
        board[$i]="$AI"
        read -r score move << EOF
$(minimax "$nextPlayer" $((depth+1)) "$alpha" "$beta")
EOF
        board[$i]=" "
        if [ $score -gt $bestScore ]; then bestScore=$score; bestMove=$i; fi
        if [ $score -gt $alpha ]; then alpha=$score; fi
        if [ $beta -le $alpha ]; then break; fi
      fi
    done
    printf "%s %s\n" $bestScore $bestMove
  else
    bestScore=1000; bestMove=-1; nextPlayer="$AI"
    for i in 0 1 2 3 4 5 6 7 8; do
      if [ "${board[$i]}" = " " ]; then
        board[$i]="$HUMAN"
        read -r score move << EOF
$(minimax "$nextPlayer" $((depth+1)) "$alpha" "$beta")
EOF
        board[$i]=" "
        if [ $score -lt $bestScore ]; then bestScore=$score; bestMove=$i; fi
        if [ $score -lt $beta ]; then beta=$score; fi
        if [ $beta -le $alpha ]; then break; fi
      fi
    done
    printf "%s %s\n" $bestScore $bestMove
  fi
}

ai_move() {
  local score move i
  read -r score move << EOF
$(minimax "$AI" 0 -1000 1000)
EOF
  if [ "$move" -lt 0 ] 2>/dev/null; then
    for i in 0 1 2 3 4 5 6 7 8; do
      if [ "${board[$i]}" = " " ]; then move=$i; break; fi
    done
  fi
  board[$move]="$AI"
}

human_move() {
  local pos idx
  while :; do
    printf "Your move X. Choose 1-9: " "$HUMAN"
    IFS= read -r pos
    case "$pos" in
      [1-9]) idx=$((pos-1));;
      *) printf "%s\n" "Please enter a number from 1 to 9."; continue;;
    esac
    if [ "${board[$idx]}" != " " ]; then
      printf "%s\n" "That cell is taken. Try another."; continue
    fi
    board[$idx]="$HUMAN"; break
  done
}

# Portable uppercase helper
to_upper() { printf '%s' "$1" | tr '[:lower:]' '[:upper:]'; }

choose_symbols_and_turn() {
  printf "\n"
  while :; do
    printf "%s" "Do you want to be X or O? [X/O]: "
    IFS= read -r ans; ans="$(to_upper "$ans")"
    if [ "$ans" = X ]; then HUMAN="X"; AI="O"; break
    elif [ "$ans" = O ]; then HUMAN="O"; AI="X"; break
    else printf "%s\n" "Please type X or O."; fi
  done
  while :; do
    printf "%s" "Who goes first? [Y]ou or [A]I: "
    IFS= read -r ans; ans="$(to_upper "$ans")"
    if [ "$ans" = Y ]; then TURN="HUMAN"; break
    elif [ "$ans" = A ]; then TURN="AI"; break
    else printf "%s\n" "Please type Y or A."; fi
  done
}

play_game() {
  board=(" " " " " " " " " " " " " " " " " ")
  choose_symbols_and_turn
  while :; do
    print_board
    winner=$(check_winner)
    if [ "$winner" != "N" ]; then
      case "$winner" in
        "$HUMAN") printf "You cannot win, human!!!\n\n";;
        "$AI")    printf "AI wins!\n\n";;
        D)         printf "It's a draw.\n\n";;
      esac
      break
    fi

    if [ "$TURN" = "HUMAN" ]; then
      human_move; TURN="AI"
    else
      printf "AI is thinking...\n"
      ai_move; TURN="HUMAN"
    fi
  done
}

main() {
  while :; do
    play_game
    printf "%s" "Play again? [Y/n]: "
    IFS= read -r again; again="$(to_upper "$again")"
    if [ "$again" = N ]; then
      printf "%s\n" "Thanks for playing!"; break
    fi
  done
}

main
