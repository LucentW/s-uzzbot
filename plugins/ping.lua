do

  function run(msg, matches)
    return "pong"
  end

  return {
    description = "Comandamenti e glorificazioni all'HYDRA",
    patterns = {
      "^!ping$",
    },
    run = run
  }

end
