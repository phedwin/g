output="$(g --no-update -term-width 200 --no-config --icons --permission --size --group --owner --header --footer tests/test_data )"
echo "$output" | diff - tests/header-footer.stdout