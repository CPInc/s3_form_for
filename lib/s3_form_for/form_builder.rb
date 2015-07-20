module ActionView::Helpers
  class FormBuilder

    view_paths = Rails::Application::Configuration.new(Rails.root).paths["app/views"]
    av_helper = ActionView::Base.new view_paths

    def s3_progress_bar
      @template.render '/shared/s3_form/progress_bar'
    end

    def s3_file(method, options = {}, html_options = {})
      options = options.with_indifferent_access
      available_mime, accept_mime = accepted_formats(options)


      k = renderer.render '/shared/s3_form/file_input', locals: {
                options: options,
                available_mime: available_mime,
                accept_mime: accept_mime,
                html_options: html_options
      }

      unless options[:without_progress_bar]
        k << @template.render('/shared/s3_form/progress_bar')
      end
      k
    end

    def logo_s3_file(method, options = {}, html_options = {})
      options = options.with_indifferent_access
      available_mime, accept_mime = accepted_formats(options)

      renderer.render '/shared/s3_form/logo_file', locals: {
          options: options,
          available_mime: available_mime,
          accept_mime: accept_mime,
          html_options: html_options
      }
    end


    private

    def renderer
      @renderer ||=  ActionView::Base.new Rails.root.join('app/views')
    end

    def accepted_formats(options)
      browser_name = Browser.new(ua: options[:http_user_agent], accept_language: 'en-us').name

      all_formats = {}
      all_formats.merge!(options[:photo_formats]) if options[:photo_formats].present?
      all_formats.merge!(options[:video_formats]) if options[:video_formats].present?
      all_formats.merge!(options[:report_formats]) if options[:report_formats].present?
      all_formats.merge!(options[:dicom_formats]) if options[:dicom_formats].present?

      available_mime = all_formats.values.flatten

      accept_mime = case browser_name
                      when 'Chrome'
                        ''
                      when 'Firefox'
                        all_formats = []
                        all_formats << 'image/*'  if options[:photo_formats].present?
                        all_formats << 'video/*' if options[:video_formats].present?
                        all_formats << 'application/*' if options[:report_formats].present? || options[:dicom_formats].present?
                        all_formats.join(', ')
                      else
                        available_mime.join(', ')
                    end

      return [available_mime, accept_mime]
    end
  end
end
