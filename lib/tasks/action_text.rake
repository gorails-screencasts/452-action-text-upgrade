namespace :action_text do
  task refresh_embeds: :environment do
    ActionText::RichText.where.not(body: nil).find_each do |trix|
      next unless trix.embeds.size.positive?

      trix.body.fragment.find_all("action-text-attachment").each do |node|
        embed = trix.embeds.find { |attachment| attachment.filename.to_s == node["filename"] && attachment.byte_size.to_s == node["filesize"] }

        # Files
        if embed.present?
          node.attributes["url"].value = Rails.application.routes.url_helpers.rails_storage_redirect_url(embed.blob, host: "localhost:3000")
          node.attributes["sgid"].value = embed.attachable_sgid

        # User mentions
        elsif (user = User.find_by(id: Base64.decode64(node["sgid"])[/User\/(\d+)/, 1]))
          node.attributes["sgid"].value = user.attachable_sgid
        end
      end

      trix.update_column :body, trix.body.to_s
    end
  end
end
