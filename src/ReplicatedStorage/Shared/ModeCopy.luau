local ModeCopy = {}

local MODES = {
	Classic4Digit = "classic_4_digit",
	HigherLower100 = "higher_lower_100",
}

local COPY_BY_MODE = {
	[MODES.HigherLower100] = {
		menuSubtitle = "Pick a number, read Higher / Lower feedback, and solve first.",
		menuTag = "1-100 NUMBER DUEL",
		menuHeading = "Narrow the range. Call the number.",
		menuBody = "Set a secret number from 1 to 100, trade guesses, and use Higher, Lower, or Correct feedback to solve first.",
		menuInfo = "Both players submit a secret number from 1 to 100. On each turn, guess the opponent's number. Feedback tells you whether the answer is Higher, Lower, or Correct.",
		menuFootnote = "If the first player solves first, the second player still gets one final chance to tie.",
		howToPlay = "Choose a secret number from 1 to 100. When the round starts, take turns guessing the opponent's number. Feedback is only Higher, Lower, or Correct. The first player to guess correctly wins, with a final tie chance for the second player if needed.",
		matchSubtitle = "Race to find the hidden number. Feedback tells you Higher, Lower, or Correct.",
		secretHelp = "Choose the 1-100 number your opponent is trying to find.",
		guessHelp = "Submit guesses from 1 to 100. Feedback says whether the answer is Higher, Lower, or Correct.",
		historyHint = "Each entry shows the guess and whether the answer is Higher, Lower, or Correct.",
		secretPlaceholder = "Enter 1-100",
		guessPlaceholder = "Enter 1-100",
		enterSecretStatus = "Enter your secret number",
		waitingSecretStatus = "Waiting for opponent number",
		secretActiveState = "Active: enter your number",
		secretSavedState = "Number saved",
		guessLockedState = "Locked until numbers are in",
		guessWaitingState = "Waiting for guess phase",
		secretLockedState = "Number locked",
		guessActiveState = "Active: submit a number",
		guessOpponentState = "Opponent is guessing",
		youWonSubtitle = "You found the number and closed the round.",
		opponentWonSubtitle = "Opponent found your number first.",
		tieSubtitle = "Both players found the number on the final exchange.",
		highLowSummary = "No locked digits in this mode. Use Higher / Lower history to narrow the hidden number.",
	},

	[MODES.Classic4Digit] = {
		menuSubtitle = "Lock exact digits before your opponent cracks your code.",
		menuTag = "2-PLAYER SHOWDOWN",
		menuHeading = "Read the pattern. Win the race.",
		menuBody = "Set a 4-digit secret, trade guesses, and lock exact hits before the other player solves your full code.",
		menuInfo = "Both players submit a secret. On each turn, enter a 4-digit guess. Exact-position matches lock in and stay visible for the rest of the round.",
		menuFootnote = "If the first player solves first, the second player still gets one final chance to tie.",
		howToPlay = "Choose a 4-digit secret. When the round starts, take turns making 4-digit guesses. Each exact-position match becomes locked, helping narrow the answer. The player who fully reveals the opponent's code wins, with a final tie chance for the second player if needed.",
		matchSubtitle = "Race to solve the code. Locked digits stay revealed for the rest of the round.",
		secretHelp = "Choose the 4-digit code your opponent is trying to reveal.",
		guessHelp = "Submit guesses on your turn. Exact digits lock permanently into place.",
		historyHint = "Each entry shows the guess and currently locked feedback.",
		secretPlaceholder = "Enter 4 digits",
		guessPlaceholder = "Enter 4 digits",
		enterSecretStatus = "Enter your secret",
		waitingSecretStatus = "Waiting for opponent secret",
		secretActiveState = "Active: enter your code",
		secretSavedState = "Secret saved",
		guessLockedState = "Locked until secrets are in",
		guessWaitingState = "Waiting for guess phase",
		secretLockedState = "Secret locked",
		guessActiveState = "Active: submit a guess",
		guessOpponentState = "Opponent is guessing",
		youWonSubtitle = "You cracked the code and closed the round.",
		opponentWonSubtitle = "Opponent solved your code first.",
		tieSubtitle = "Both players solved it on the final exchange.",
		highLowSummary = "",
	},
}

function ModeCopy.get(modeId)
	return COPY_BY_MODE[modeId] or COPY_BY_MODE[MODES.Classic4Digit]
end

return ModeCopy
