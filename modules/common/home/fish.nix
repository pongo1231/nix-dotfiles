{ pkgs, lib, ... }:
{
  programs.fish = {
    enable = true;

    shellAliases = {
      "cd.." = "cd ..";
      cpufreq = "watch -n.1 'grep \"^[c]pu MHz\" /proc/cpuinfo'";

      ksminfo = "grep -r . /sys/kernel/mm/ksm";
      ksmprofit = "echo | awk -v profit=$(cat /sys/kernel/mm/ksm/general_profit) '{print \"\\033[35m\"profit / 1024 / 1024\" MB\\033[0m\"}'";

      thpinfo = "grep HugePages /proc/meminfo";
    };

    shellInit = ''
      set async_prompt_functions fish_prompt

      function fish_command_not_found
        , $argv
        return $status
      end

      fish_add_path -maP ~/.local/bin
    '';

    plugins =
      let
        plugins = with pkgs.fishPlugins; [
          fzf-fish
          autopair
          colored-man-pages
          transient-fish
          #sponge
          z
          forgit
          async-prompt
        ];
      in
      lib.foldl' (
        acc: x:
        acc
        ++ [
          {
            inherit (x) name src;
          }
        ]
      ) [ ] plugins;
  };
}
