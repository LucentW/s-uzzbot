do

function run(msg, matches)
  local answers = {'.NSFW content above\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n NSFW content above'}
  return answers[math.random(#answers)]
end

return {
  description = "Clear Screen from NSFW",
  usage = "Use !clear or !nsfw to hide nsfw content",
  patterns = {"^!clear",
  "^!nsfw"},
  run = run
}

end
