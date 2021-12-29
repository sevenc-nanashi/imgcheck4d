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

def check_images(images)
  barrier = Async::Barrier.new
  results = []
  images.each_with_index do |image, i|
    barrier.async do
      results[i] = check_image(image.url).wait
    end
  end
  barrier.wait

  results.map.with_index do |result, i|
    if result[:status] == "error"
      Discorb::Embed.new(
        "#{i + 1}番目の画像",
        "チェックに失敗しました。\n #{result[:message_ja].lines.map { |line| "> #{line}" }.join("\n")}",
        url: result[:base_url],
        color: Discorb::Color[:red],
        thumbnail: result[:base_url],
      )
    elsif result[:found]
      Discorb::Embed.new(
        "#{i + 1}番目の画像",
        "#{result[:count]} 個の画像が見つかりました。\n[検索結果を見る](#{result[:resulturl]})",
        url: result[:base_url],
        color: Discorb::Color[:green],
        thumbnail: result[:base_url],
      )
    else
      Discorb::Embed.new(
        "#{i + 1}番目の画像",
        "画像が見つかりませんでした。",
        url: result[:base_url],
        color: Discorb::Color[:yellow],
        thumbnail: result[:base_url],
      )
    end
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
  embeds = check_images(images)
  interaction.post(embeds: embeds, ephemeral: true)
end
client.on :message do |message|
  next unless message.content =~ /<@!?#{client.user.id}>/
  unless message.message_reference
    next message.reply("チェックしたい画像が添付されているメッセージに返信してください。").wait.then { |m| sleep 5; m.delete! }
  end
  msg = message.channel.fetch_message(message.message_reference.message_id).wait
  images = msg.attachments.filter { |a| a.content_type.start_with?("image") }
  if images.length == 0
    next message.reply("画像が添付されていません。").wait.then { |m| sleep 5; m.delete! }
  end
  message.reply("#{images.length} 個のファイルをチェックしています。")
  embeds = check_images(images)
  result_msg = message.reply(embeds: embeds).wait
  result_msg.react_with Discorb::UnicodeEmoji["wastebasket"]
  begin
    client.event_lock(:reaction_add, 30) { |event|
      event.emoji == Discorb::UnicodeEmoji["wastebasket"] &&
      event.message.id == result_msg.id &&
      not((event.user || client.fetch_user(event.user_id).wait).bot?)
    }.wait
  rescue Discorb::TimeoutError
  else
    result_msg.delete!
  end
end

client.run ENV["TOKEN"]
