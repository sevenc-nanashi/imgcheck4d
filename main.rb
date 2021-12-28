require "discorb"
require "dotenv"
require "http"

Dotenv.load

def check_image(url)
  Async do
    response = HTTP.get("https://api.irucabot.com/imgcheck/check_url", params: { url: url })
    data = JSON.parse(response.body, symbolize_names: true)
    data[:base_url] = url
    next data
  end
end

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.message_command("拾い画チェック") do |interaction, message|
  images = message.attachments.filter { |a| a.content_type.start_with?("image") }
  if images.length == 0
    next interaction.post("画像が添付されていません。", ephimeral: true)
  end
  interaction.post("#{images.length} 個のファイルをチェックしています。", ephemeral: true)
  barrier = Async::Barrier.new
  results = []
  images.each_with_index do |image, i|
    barrier.async do
      results[i] = check_image(image.url).wait
    end
  end
  barrier.wait

  message = results.map.with_index do |result, i|
    if result[:status] == "error"
      <<~EOS
        :no_entry_sign:**[#{i + 1}番目の画像](#{result[:base_url]})**

        チェックに失敗しました。
        #{result[:message_ja].lines.map { |line| "> #{line}" }.join("\n")}
      EOS
    elsif result[:found]
      <<~EOS
        :white_check_mark:**[#{i + 1}番目の画像](#{result[:base_url]})**

        #{result[:count]} 個の画像が見つかりました。
        [検索結果URL](#{result[:url]})
      EOS
    else
      <<~EOS
        :heavy_check_mark:**[#{i + 1}番目の画像](#{result[:base_url]})**

        画像が見つかりませんでした。
      EOS
    end
  end.join("\n")
  interaction.post(message, ephemeral: true)
end

client.run ENV["TOKEN"]
