import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

function getMimeType(extension: string): string {
  const ext = extension.toLowerCase()

  if (ext === "jpg" || ext === "jpeg") return "image/jpeg"
  if (ext === "png") return "image/png"
  if (ext === "pdf") return "application/pdf"
  return "text/plain"
}

function createSupabaseClient(req: Request) {
  const authHeader = req.headers.get("Authorization")

  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    {
      global: {
        headers: authHeader ? { Authorization: authHeader } : {},
      },
      auth: {
        persistSession: false,
      }
    }
  )
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const supabase = createSupabaseClient(req)

    const authHeader = req.headers.get("Authorization")
    const token = authHeader ? authHeader.replace("Bearer ", "") : ""

    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      throw new Error("Unauthorized user")
    }

    const formData = await req.formData()
    const file = formData.get("file") as File
    const folderName = formData.get("folderName") as string
    const fileName = formData.get("fileName") as string
    const fileType = formData.get("fileType") as string
    const extractedText = formData.get("extractedText") as string

    if (!file) throw new Error("Missing file")

    const filePath = `${user.id}/${folderName}/${fileName}`
    const arrayBuffer = await file.arrayBuffer()

    const { error: uploadError } = await supabase.storage
      .from("StudyMaterials")
      .upload(filePath, arrayBuffer, {
        contentType: getMimeType(fileType),
        upsert: true,
      })

    if (uploadError) throw uploadError

    const { data, error: dbError } = await supabase
      .from("study_materials")
      .insert({
        file_type: fileType,
        raw_text: extractedText,
        file_path: filePath,
        student_id: user.id,
      })
      .select()

    if (dbError) throw dbError

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    })

  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    )
  }
})