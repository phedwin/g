output="$(g --no-update -term-width 200 --no-config --icons --permission --size --footer tests/test_data )"
echo "$output" | diff - tests/footer.stdout
