local GuessValidator = {}

local SECRET_LENGTH = 4

function GuessValidator.isFourDigitValue(value)
	if type(value) ~= "string" then
		return false
	end

	if #value ~= SECRET_LENGTH then
		return false
	end

	return string.match(value, "^%d%d%d%d$") ~= nil
end

function GuessValidator.validateSecret(secret)
	if not GuessValidator.isFourDigitValue(secret) then
		return false, "Secret must be a 4-digit string."
	end

	return true
end

function GuessValidator.validateGuess(guess)
	if not GuessValidator.isFourDigitValue(guess) then
		return false, "Guess must be a 4-digit string."
	end

	return true
end

return GuessValidator
