import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const authHeader = req.headers.get("Authorization");

    if (!authHeader) {
      return Response.json(
        { error: "Missing authorization header" },
        { status: 401 },
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      {
        global: {
          headers: {
            Authorization: authHeader,
          },
        },
      },
    );

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return Response.json(
        { error: "Unauthorized" },
        { status: 401 },
      );
    }

    const body = await req.json();
    const action = body.action;

    switch (action) {
      case "ensureStudent":
        return await ensureStudent(supabase, user.id);

      case "insertStudyMaterial":
        return await insertStudyMaterial(
          supabase,
          user.id,
          body,
        );

      case "saveProcessedText":
        return await saveProcessedText(
          supabase,
          body,
        );

      case "saveSummary":
        return await saveSummary(
          supabase,
          body,
        );

      case "saveFlashcards":
        return await saveFlashcards(
          supabase,
          body,
        );

      case "saveQuiz":
        return await saveQuiz(
          supabase,
          body,
        );

      case "saveQuizResult":
        return await saveQuizResult(
          supabase,
          user.id,
          body,
        );

      case "fetchMaterialsByFolder":
        return await fetchMaterialsByFolder(
          supabase,
          user.id,
          body.folderName,
        );

      default:
        return Response.json(
          { error: "Invalid action" },
          { status: 400 },
        );
    }
  } catch (e) {
    return Response.json(
      {
        error: e.message,
      },
      {
        status: 500,
      },
    );
  }
});

async function ensureStudent(supabase: any, userId: string) {
  const { data, error } = await supabase
    .from("students")
    .upsert({
      id: userId,
    })
    .select()
    .single();

  if (error) throw error;

  return Response.json(data);
}

async function insertStudyMaterial(
  supabase: any,
  userId: string,
  body: any,
) {
  await ensureStudent(supabase, userId);

  const { data, error } = await supabase
    .from("study_materials")
    .insert({
      student_id: userId,
      file_type: body.fileType,
      file_path: body.filePath,
      raw_text: body.rawText,
    })
    .select()
    .single();

  if (error) throw error;

  return Response.json(data);
}

async function saveProcessedText(
  supabase: any,
  body: any,
) {
  const { data, error } = await supabase
    .from("processed_texts")
    .insert({
      material_id: body.materialId,
      processed_text: body.processedText,
    })
    .select()
    .single();

  if (error) throw error;

  return Response.json(data);
}

async function saveSummary(
  supabase: any,
  body: any,
) {
  const { data, error } = await supabase
    .from("summaries")
    .insert({
      material_id: body.materialId,
      summary_text: body.summaryText,
    })
    .select()
    .single();

  if (error) throw error;

  return Response.json(data);
}

async function saveFlashcards(
  supabase: any,
  body: any,
) {
  const { materialId, flashcards } = body;

  const { data: setData, error: setError } = await supabase
    .from("flashcard_sets")
    .insert({
      material_id: materialId,
    })
    .select()
    .single();

  if (setError) throw setError;

  const rows = flashcards.map((card: any) => ({
    set_id: setData.id,
    material_id: materialId,
    question: card.front,
    answer: card.back,
  }));

  const { data, error } = await supabase
    .from("flashcards")
    .insert(rows)
    .select();

  if (error) throw error;

  return Response.json({
    set: setData,
    cards: data,
  });
}

async function saveQuiz(
  supabase: any,
  body: any,
) {
  const { materialId, questions } = body;

  const { data: quiz, error: quizError } = await supabase
    .from("quizzes")
    .insert({
      material_id: materialId,
    })
    .select()
    .single();

  if (quizError) throw quizError;

  for (const q of questions) {
    const { data: question, error: questionError } =
      await supabase
        .from("questions")
        .insert({
          quiz_id: quiz.id,
          question_text: q.question,
        })
        .select()
        .single();

    if (questionError) throw questionError;

    const choiceRows = q.options.map(
      (option: string, index: number) => ({
        question_id: question.id,
        choice_text: option,
        is_correct: index === q.correctIndex,
      }),
    );

    const { error: choiceError } = await supabase
      .from("choices")
      .insert(choiceRows);

    if (choiceError) throw choiceError;
  }

  return Response.json(quiz);
}

async function saveQuizResult(
  supabase: any,
  userId: string,
  body: any,
) {
  await ensureStudent(supabase, userId);

  const { data, error } = await supabase
    .from("quiz_results")
    .insert({
      quiz_id: body.quizId,
      student_id: userId,
      score: body.score,
    })
    .select()
    .single();

  if (error) throw error;

  return Response.json(data);
}

async function fetchMaterialsByFolder(
  supabase: any,
  userId: string,
  folderName: string,
) {
  const folderPath = `${userId}/${folderName}`;

  const { data: files, error: storageError } =
    await supabase.storage
      .from("StudyMaterials")
      .list(folderPath);

  if (storageError) throw storageError;

  const filePaths = files.map(
    (f: any) => `${folderPath}/${f.name}`,
  );

  const { data, error } = await supabase
    .from("study_materials")
    .select("*")
    .eq("student_id", userId)
    .in("file_path", filePaths)
    .order("created_at", {
      ascending: false,
    });

  if (error) throw error;

  return Response.json(data);
}