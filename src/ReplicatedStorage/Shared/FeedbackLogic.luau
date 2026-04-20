local FeedbackLogic = {}

-- Compare guess with secret and return correct positions
function FeedbackLogic.getExactMatches(secret, guess)
	local matches = {}

	for i = 1, #secret do
		if string.sub(secret, i, i) == string.sub(guess, i, i) then
			matches[i] = string.sub(secret, i, i)
		end
	end

	return matches
end

-- Merge locked positions
function FeedbackLogic.mergeLocked(previousLocked, newMatches)
	local result = {}

	for i = 1, 4 do
		if previousLocked[i] then
			result[i] = previousLocked[i]
		elseif newMatches[i] then
			result[i] = newMatches[i]
		end
	end

	return result
end

-- Check win condition
function FeedbackLogic.isSolved(locked)
	for i = 1, 4 do
		if not locked[i] then
			return false
		end
	end
	return true
end

return FeedbackLogic
