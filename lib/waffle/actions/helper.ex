defmodule Waffle.Helper do
  def md5_regex(hash) do
    case Regex.match?(~r/^[a-f0-9]{32}$/iu, hash) do
      true ->
        hash

      false ->
        nil
    end
  end

  def extract_metadata(%{path: path, file_name: file_name}) do
    case file_type(file_name) do
      :video ->
        fetch_video_metadata(path)

      :image ->
        fetch_image_metadata(path)

      _ ->
        %{}
    end
    |> Map.merge(%{"md5" => calculate_md5(path)})
  end

  def calculate_md5(path) do
    case System.cmd("sh", [
           "-c",
           "md5sum #{path}"
         ]) do
      {output, 0} ->
        String.split(output, " ") |> List.first() |> md5_regex

      _ ->
        nil
    end
  end

  def fetch_image_metadata(path) do
    case System.cmd("sh", [
           "-c",
           "exiftool -json #{path}"
         ]) do
      {output, 0} ->
        [
          %{
            "ImageWidth" => width,
            "ImageHeight" => height,
            "ImageSize" => image_size
          }
        ] = Jason.decode!(output)

        calculated_aspect = Float.round(width / height, 2)
        vertical = calculated_aspect < 1.0

        %{
          "width" => width,
          "height" => height,
          "file_type" => "image",
          "dim" => image_size,
          "vertical" => vertical,
          "duration" => 0
        }

      _ ->
        %{}
    end
  end

  defp fetch_video_metadata(path) do
    case System.cmd("sh", [
           "-c",
           "ffprobe -hide_banner -loglevel fatal -show_error -show_format -show_streams -show_programs -show_chapters -show_private_data -print_format json -show_format #{path}"
         ]) do
      {output, 0} ->
        %{
          "format" => %{"duration" => duration} = format,
          "streams" => [
            %{
              "width" => width,
              "height" => height
            } = video_stream
            | _
          ]
        } = Jason.decode!(output)

        calculated_aspect = Float.round(width / height, 2)
        vertical = calculated_aspect < 1.0
        {float, _} = Float.parse(duration)

        parsed_duration = Float.ceil(float) |> trunc()

        Map.take(format, ["bit_rate", "format_name", "size", "start_time"])
        |> Map.merge(
          Map.take(video_stream, ["codec_name", "display_aspect_ratio", "width", "height"])
        )
        |> Map.merge(%{
          "calculated_aspect" => calculated_aspect,
          "vertical" => vertical,
          "file_type" => "video",
          "dim" => "#{width}x#{height}",
          "duration" => parsed_duration
        })

      _ ->
        %{}
    end
  end

  def file_type(filename) do
    ext = String.split(filename, ".") |> List.last()

    cond do
      ext in Waffle.Helper.image_file_ext() ->
        :image

      ext in Waffle.Helper.video_file_ext() ->
        :video

      true ->
        :unknown
    end
  end

  def image_file_ext do
    [
      "ase",
      "art",
      "bmp",
      "blp",
      "cd5",
      "cit",
      "cpt",
      "cr2",
      "cut",
      "dds",
      "dib",
      "djvu",
      "egt",
      "exif",
      "gif",
      "gpl",
      "grf",
      "icns",
      "ico",
      "iff",
      "jng",
      "jpeg",
      "jpg",
      "jfif",
      "jp2",
      "jps",
      "lbm",
      "max",
      "miff",
      "mng",
      "msp",
      "nef",
      "nitf",
      "ota",
      "pbm",
      "pc1",
      "pc2",
      "pc3",
      "pcf",
      "pcx",
      "pdn",
      "pgm",
      "PI1",
      "PI2",
      "PI3",
      "pict",
      "pct",
      "pnm",
      "pns",
      "ppm",
      "psb",
      "psd",
      "pdd",
      "psp",
      "px",
      "pxm",
      "pxr",
      "qfx",
      "raw",
      "rle",
      "sct",
      "sgi",
      "rgb",
      "int",
      "bw",
      "tga",
      "tiff",
      "tif",
      "vtf",
      "xbm",
      "xcf",
      "xpm",
      "3dv",
      "amf",
      "ai",
      "awg",
      "cgm",
      "cdr",
      "cmx",
      "dxf",
      "e2d",
      "egt",
      "eps",
      "fs",
      "gbr",
      "odg",
      "svg",
      "stl",
      "vrml",
      "x3d",
      "sxd",
      "v2d",
      "vnd",
      "wmf",
      "emf",
      "art",
      "xar",
      "png",
      "webp",
      "jxr",
      "hdp",
      "wdp",
      "cur",
      "ecw",
      "iff",
      "lbm",
      "liff",
      "nrrd",
      "pam",
      "pcx",
      "pgf",
      "sgi",
      "rgb",
      "rgba",
      "bw",
      "int",
      "inta",
      "sid",
      "ras",
      "sun",
      "tga",
      "heic",
      "heif"
    ]
  end

  def video_file_ext do
    [
      "webm",
      "mkv",
      "flv",
      "vob",
      "ogv",
      "ogg",
      "rrc",
      "gifv",
      "mng",
      "mov",
      "avi",
      "qt",
      "wmv",
      "yuv",
      "rm",
      "asf",
      "amv",
      "mp4",
      "m4p",
      "m4v",
      "mpg",
      "mp2",
      "mpeg",
      "mpe",
      "mpv",
      "m4v",
      "svi",
      "3gp",
      "3g2",
      "mxf",
      "roq",
      "nsv",
      "flv",
      "f4v",
      "f4p",
      "f4a",
      "f4b",
      "mod"
    ]
  end
end
