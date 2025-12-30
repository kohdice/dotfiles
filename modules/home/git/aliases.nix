{
  a = "!git status --short | peco | awk '{print $2}' | xargs git add";
  ap = "apply";
  br = "branch";
  cm = "commit";
  co = "checkout";
  cp = "cherry-pick";
  df = "!git hs | peco | awk '{print $2}' | xargs -I {} git diff {}^ {}";
  fe = "fetch";
  hs = ''log --pretty=format:"%C(red)%h %Creset%cd %C(blue)[%cn] %Creset%s%C(yellow)%d%C(reset)" --graph --date=relative --decorate --all'';
  lg = ''log --graph --name-status --pretty=format:"%C(red)%h %C(reset)(%cd) %C(blue)[%cn] %Creset%s %C(yellow)%d%Creset" --date=relative'';
  pl = "!git pull origin $(git rev-parse --abbrev-ref HEAD)";
  ps = "!git push origin $(git rev-parse --abbrev-ref HEAD)";
  pst = "push origin --tags";
  rb = "rebase";
  rs = "reset --soft HEAD^";
  ru = "remote update -p";
  st = "status";
  sw = "switch";
  find = ''!f() { git log --pretty=format:"%h %cd [%cn] %s%d" --date=relative -S'pretty' -S"$@" | peco | awk '{print $1}' | xargs -I {} git diff {}^ {}; }; f'';
  edit-unmerged = "!f() { git ls-files --unmerged | cut -f2 | sort -u ; }; nvim `f`";
  add-unmerged = "!f() { git ls-files --unmerged | cut -f2 | sort -u ; }; git add `f`";
}
