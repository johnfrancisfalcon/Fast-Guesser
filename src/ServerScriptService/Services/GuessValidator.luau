local GuessValidator = {}

local SECRET_LENGTH = 4
local MIN_HIGH_LOW_VALUE = 1
local MAX_HIGH_LOW_VALUE = 100

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

function GuessValidator.isOneToOneHundredValue(value)
	if type(value) ~= "string" then
		return false
	end

	if string.match(value, "^%d+$") == nil then
		return false
	end

	local numberValue = tonumber(value)
	return numberValue ~= nil and numberValue >= MIN_HIGH_LOW_VALUE and numberValue <= MAX_HIGH_LOW_VALUE
end

function GuessValidator.validateHighLowSecret(secret)
	if not GuessValidator.isOneToOneHundredValue(secret) then
		return false, "Secret must be a number from 1 to 100."
	end

	return true
end

function GuessValidator.validateHighLowGuess(guess)
	if not GuessValidator.isOneToOneHundredValue(guess) then
		return false, "Guess must be a number from 1 to 100."
	end

	return true
end

return GuessValidator
