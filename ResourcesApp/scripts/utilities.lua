-- math

function sign (n)
	if n >= 0 then
		return 1
	else
		return -1
	end
end

function clamp (n, a, b) 
	if n < a then
		return a
	elseif n > b then
		return b
	else
		return n
	end
end

function randomIntRange (a, b)
	return game.mathRandomIntRange (a, b)
end

function randomInt ()
	return game.mathRandomInt ()
end

function randomSign ()
	local s = game.mathRandomIntRange (0, 1)
	if s == 0 then s = -1 end
	return s
end

-- score

function scoreAdd (score, sound)
		game.scoreAdd (score)
		
		local s
		if score > 0 then 
			s = "+%d" 
		else
			s = "%d"
		end
		game.hudShowTimerLabel (string.format (s, score) , sound)
end

-- sound

function musicVolume ()
	return game.audioMusicVolume ()
end

function setMusicVolume (volume)
	return game.audioSetMusicVolume (volume)
end

function soundEffectsVolume ()
	return game.audioSoundEffectsVolume ()
end

function setSoundEffectsVolume (volume)
	return game.audioSetSoundEffectsVolume (volume)
end

function startBackgroundMusic (filename)
	game.audioStartBackgroundMusic (filename)
end

function stopBackgroundMusic ()
	game.audioStopBackgroundMusic ()
end

function pauseBackgroundMusic ()
	game.audioPauseBackgroundMusic ()
end

function resumeBackgroundMusic ()
	game.audioResumeBackgroundMusic ()
end

function rewindBackgroundMusic ()
	game.audioRewindBackgroundMusic ()
end

function playSound (filename)
	game.audioPlaySound (filename)
end

function playSoundLoop (filename)
	return game.audioPlaySoundLoop (filename)
end

function playSoundWithPan (filename, pan)
	game.audioPlaySoundWithPan (filename, pan)
end

function stopSound (sid)
	game.audioStopSound (sid)
end

function stopAllSounds ()
	game.audioStopAllSounds ()
end

